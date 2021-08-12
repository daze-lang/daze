module codegen

import ast
import parser{is_binary_op}

pub struct CppCodeGenerator {
pub:
    ast ast.AST
}

pub fn new_cpp(ast ast.AST) CppCodeGenerator {
    return CppCodeGenerator{ast}
}

pub fn (mut gen CppCodeGenerator) run() string {
// TODO: out function is temporary here
    mut code := "#include <iostream>\n#include <vector>\n\n"
    code += "void out(std::string s) { std::cout << s << std::endl; }\n\n"
    code += "std::string tostring(auto s) { return std::to_string(s); }\n\n"


    for node in gen.ast.nodes {
        code += gen.gen(node)
    }

    return code
}

pub fn (mut gen CppCodeGenerator) gen(node ast.Node) string {
    mut code := ""

    if mut node is ast.Statement {
        code += gen.statement(node)
    } else if mut node is ast.Expr {
        code += gen.expr(node)
    }

    return code
}

fn (mut gen CppCodeGenerator) statement(node ast.Statement) string {
    mut code := ""
    if mut node is ast.FunctionDeclarationStatement {
        code = gen.fn_decl(node)
    } else if mut node is ast.FunctionArgument {
        code = gen.fn_arg(node)
    } else if mut node is ast.ModuleDeclarationStatement {
    } else if mut node is ast.ImplementBlockStatement {
        code = gen.implement_block(node)
    } else if mut node is ast.UnsafeBlock {
        code = node.body
    } else if mut node is ast.StructDeclarationStatement {
        code = gen.struct_decl(node)
    } else if mut node is ast.GlobalDecl {
        code = "#define $node.name $node.value\n"
    } else if mut node is ast.ModuleUseStatement {
        code = "include ${node.path.replace("daze::", "")}\n"
    }

    return code
}

fn (mut gen CppCodeGenerator) expr(node ast.Expr) string {
    mut code := ""
    if mut node is ast.StringLiteralExpr {
        code = gen.string_literal_expr(node)
    } else if mut node is ast.NumberLiteralExpr {
        code = gen.number_literal_expr(node)
    } else if mut node is ast.FunctionCallExpr {
        code = gen.fn_call(node)
    } else if mut node is ast.VariableExpr {
        code = gen.variable_expr(node)
    } else if mut node is ast.UnsafeBlock {
        code = node.body
    } else if mut node is ast.VariableAssignment {
        code = gen.variable_assignment(node)
    } else if mut node is ast.BinaryOp {
        code = "$node.value"
    } else if mut node is ast.ReturnExpr {
        code = gen.return_expr(node)
    } else if mut node is ast.VariableDecl {
        code = gen.variable_decl(node)
    } else if mut node is ast.RawBinaryOpExpr {
        code = node.value
    } else if mut node is ast.IfExpression {
        code = gen.if_statement(node)
    } else if mut node is ast.ForLoopExpr {
        code = gen.for_loop(node)
    } else if mut node is ast.ArrayDefinition {
        code = gen.array(node)
    } else if mut node is ast.ArrayPushExpr {
        code = "${node.target}.push_back(${gen.gen(node.value)});\n"
    } else if mut node is ast.IncrementExpr {
        code = "$node.target++;\n"
    } else if mut node is ast.DecrementExpr {
        code = "$node.target--;\n"
    } else if mut node is ast.ForInLoopExpr {
        code = gen.for_in_loop(node)
    } else if mut node is ast.IndexingExpr {
        code = gen.indexing(node)
    } else if mut node is ast.GroupedExpr {
        code = gen.grouped_expr(node)
    } else if mut node is ast.ArrayInit {
        code = gen.array_init(node)
    }

    return code
}

fn (mut gen CppCodeGenerator) fn_decl(node ast.FunctionDeclarationStatement) string {
    mut args := []string{}
    for arg in node.args {
        args << gen.fn_arg(arg)
    }
    mut code := "${gen.typename(node.return_type)} ${node.name}(${args.join(", ")}) {\n"
    for expr in node.body {
        code += gen.gen(expr)
    }
    code += "\n}\n"
    return code
}

fn (mut gen CppCodeGenerator) typename(name string) string {
    return match name {
        "String" { "std::string" }
        "Int" { "int" }
        "Any" { "auto" }
        "Void" { "void" }
        else {
            if name.contains("[]") {
                if name.contains("Any") {
                    // TODO proper, colored error message
                    panic("Arrays cant be of type Any")
                }
                "std::vector<${gen.typename(name.split("]")[1])}>"
            } else {
                println("Unhandled type: $name")
                name
            }
        }
    }
}

fn (mut gen CppCodeGenerator) fn_arg(node ast.FunctionArgument) string {
    return "${gen.typename(node.type_name)} $node.name"
}

fn (mut gen CppCodeGenerator) fn_call(node ast.FunctionCallExpr) string {
    mut args := []string{}
    for arg in node.args {
        args << gen.expr(arg).replace(";", "")
    }
    if node.calling_on != "" {
        if args.len > 0 {
            return "${node.name}(${node.calling_on}, ${args.join("")});"
        }
       return "${node.name}(${node.calling_on});"
    }
    return "${node.name}(${args.join("")});"
}

fn (mut gen CppCodeGenerator) string_literal_expr(node ast.StringLiteralExpr) string {
    return "\"$node.value\""
}

fn (mut gen CppCodeGenerator) number_literal_expr(node ast.NumberLiteralExpr) string {
    return "$node.value"
}

fn (mut gen CppCodeGenerator) variable_expr(node ast.VariableExpr) string {
    return node.value
}

fn (mut gen CppCodeGenerator) return_expr(node ast.ReturnExpr) string {
    mut body := ""
    for expr in node.value {
        body += gen.gen(expr)
    }
    return "\nreturn ${body.replace("\n", " ")};\n"
}

fn (mut gen CppCodeGenerator) variable_decl(node ast.VariableDecl) string {
    mut body := ""
    for expr in node.value {
        body += "${gen.gen(expr)} "
    }
    return "${gen.typename(node.type_name)} $node.name = $body;\n"
}

fn (mut gen CppCodeGenerator) variable_assignment(node ast.VariableAssignment) string {
    mut body := ""
    for expr in node.value {
        body += "${gen.gen(expr)} "
    }
    return "$node.name = $body;\n"
}

fn (mut gen CppCodeGenerator) struct_decl(node ast.StructDeclarationStatement) string {
    mut code := "struct $node.name {\n"
    for field in node.fields {
        code += gen.fn_arg(field) + ";"
    }

    code += "\n};\n\n"
    return code
}

fn (mut gen CppCodeGenerator) set_module(name string) {
    // gen.mod = name
}

fn (mut gen CppCodeGenerator) if_statement(node ast.IfExpression) string {
    mut code := "if (${gen.expr(node.conditional)}) {\n"
    for func in node.body {
        code += gen.gen(func)
    }

    if node.elseifs.len != 0 {
        for elsif in node.elseifs {
            code += "} else if(${gen.expr(elsif.conditional)}){\n"
            for func in elsif.body {
                code += gen.gen(func)
            }
        }
    }

    if node.else_branch.len != 0 {
        code += "} else {\n"
        for func in node.else_branch {
            code += gen.gen(func)
        }
    }

    code += "}\n"
    return code
}

fn (mut gen CppCodeGenerator) for_loop(node ast.ForLoopExpr) string {
    mut code := "\nwhile (${gen.gen(node.conditional)}) {\n"
    for func in node.body {
        code += gen.gen(func) + "\n"
    }
    code += "}\n"
    return code
}

fn (mut gen CppCodeGenerator) for_in_loop(node ast.ForInLoopExpr) string {
    mut code := "for (auto $node.container : ${gen.gen(node.target)}) {\n"
    for expr in node.body {
        code += gen.gen(expr)
    }
    code += "\n}\n"
    return code
}

fn (mut gen CppCodeGenerator) array(node ast.ArrayDefinition) string {
    mut code := "["
    mut items := []string{}

    for item in node.items {
        items << gen.gen(item)
    }

    code += "${items.join(", ")}] of $node.type_name"
    return code
}

fn (mut gen CppCodeGenerator) indexing(node ast.IndexingExpr) string {
    return "${node.var.replace("Self.", "@")}[${gen.gen(node.body)}]"
}

fn (mut gen CppCodeGenerator) grouped_expr(node ast.GroupedExpr) string {
    mut items := []string{}

    for item in node.body {
        items << gen.gen(item)
    }

    return "(${items.join(" ")})"
}

fn (mut gen CppCodeGenerator) array_init(node ast.ArrayInit) string {
    mut items := []string{}

    for item in node.body {
        items << gen.gen(item)
    }

    return "{${items.join(" ")}}"
}

fn (mut gen CppCodeGenerator) implement_block(node ast.ImplementBlockStatement) string {
    mut code := ""

    for func in node.fns {
        code += gen.fn_decl(func)
    }

    return code
}