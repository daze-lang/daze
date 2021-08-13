module codegen

import ast
import parser{is_binary_op}
import utils

pub struct CppCodeGenerator {
pub:
    ast ast.AST
pub mut:
    vars map[string]string
    fns map[string]string
    structs []string
}

pub fn new_cpp(ast ast.AST) CppCodeGenerator {
    return CppCodeGenerator{ast, map[string]string{}, map[string]string{}, []string{}}
}

pub fn (mut gen CppCodeGenerator) run() string {
    // TODO: out function is temporary here
    mut code := "#include <iostream>\n#include <vector>\n#include <typeinfo>\n#include <algorithm>\n\n"
    code += "void out(std::string s) { std::cout << s << std::endl; }\n\n"
    code += "std::string tostring(auto s) { return std::to_string(s); }\n\n"
    code += "std::string tostring(bool b) { return b ? \"true\" : \"false\"; }\n\n"
    code += "std::string tostring(char c) { std::string s; s.push_back(c); return s; }\n\n"

    for type_name in get_built_in_types() {
        code += "std::string type($type_name s) { return \"${type_name.replace("std::", "")}\"; }\n\n"
    }

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
    } else if mut node is ast.CharLiteralExpr {
        code = "'$node.value'"
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
    } else if mut node is ast.StructInitialization {
        code = gen.struct_init(node)
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
    } else if mut node is ast.PipeExpr {
        code = gen.pipe(node)
    }

    return code
}

fn (mut gen CppCodeGenerator) fn_decl(node ast.FunctionDeclarationStatement) string {
    mut args := []string{}
    for arg in node.args {
        args << gen.fn_arg(arg)
    }

    mut code := ""
    if node.name == "main" {
        for struct_type in gen.structs {
            code += "std::string type($struct_type s) { return \"$struct_type\"; }\n\n"
        }
    }

    code += "${gen.typename(node.return_type)} ${node.name}(${args.join(", ")}) {\n"
    for expr in node.body {
        code += gen.gen(expr)
    }
    gen.fns[node.name] = gen.typename(node.return_type)
    code += "\n}\n\n"
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
                    utils.codegen_error("Arrays cant be of type Any")
                }
                "std::vector<${gen.typename(name.split("]")[1])}>"
            } else {
                // println("Unhandled type: $name")
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

    mut fn_name := node.name
    type_of_callee := gen.vars[node.calling_on]
    if type_of_callee != "" && gen.structs.contains(type_of_callee) {
        fn_name = "struct_${type_of_callee}_$fn_name"
    }

    /*
    TODO This allows calling functions as such

    Do we need this?

    some_variable := "Some name";
    some_name.str(); => str(some_name);
    */

    if node.calling_on != "" {
        if args.len > 0 {
            return "${fn_name}(${node.calling_on}, ${args.join("")});\n".replace("; ;", "")
        }
       return "${fn_name}(${node.calling_on});\n".replace("; ;", "")
    }
    return "${fn_name}(${args.join("")});\n".replace("; ;", "")
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
    mut type_name := node.type_name

    for expr in node.value {
        body += "${gen.gen(expr)} "
    }

    cast := node.value[0]
    if cast is ast.StructInitialization {
        type_name = cast.name
    }

    gen.vars[node.name] = gen.typename(type_name)
    return "${gen.typename(type_name)} $node.name = $body;\n"
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

    gen.structs << node.name

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

fn (mut gen CppCodeGenerator) pipe(node ast.PipeExpr) string {
    mut code := []string{}
    mut paren_count := 0
    mut previous := ast.Expr{}

    for i, element in node.body {
        if element is ast.VariableExpr {
            if element.value in ["true", "false"] {
                utils.codegen_error("Pipes can't start with a boolean.")
            }

            if element.value.starts_with(".") {
                cast := previous
                if cast is ast.FunctionCallExpr {
                    if cast.name.starts_with("struct") {
                        parts := cast.name.split("_")
                        code << "${parts[0]}_${parts[1]}_${element.value.replace(".", "")}("
                    } else {
                        code << "struct_${gen.fns[cast.name]}_${element.value.replace(".", "")}("
                    }
                } else if cast is ast.VariableExpr {
                    mut type_info := gen.vars[cast.value]
                    if type_info == "" {
                        type_info = gen.fns[cast.value]
                    }

                    if is_built_in_type(type_info) {
                        utils.codegen_error("Calling an accessor on anything but a struct / function call is illegal.")
                    }

                    code << "struct_${type_info}_${element.value.replace(".", "")}("
                } else {
                    utils.codegen_error("Calling an accessor on anything but a struct / function call is illegal.")
                }
            } else {
                if gen.vars.keys().contains(element.value) {
                    code << "${element.value}"
                    paren_count--
                } else {
                    code << "${element.value}("
                }
            }
        } else if element is ast.StringLiteralExpr || element is ast.NumberLiteralExpr || element is ast.CharLiteralExpr {
            if i != 0 {
                utils.codegen_error("Pipelines can't have string / int pipes, only function calls.")
            }
            code << "[](){ return ${gen.expr(element)}; }()"
            paren_count--
        } else if element is ast.FunctionCallExpr {
            code << "${gen.expr(element)}".replace(";", "")
            paren_count--
        }

        paren_count++
        previous = element
    }

    return code.reverse().join("") + ")".repeat(paren_count) + ";\n"
}

fn (mut gen CppCodeGenerator) struct_init(node ast.StructInitialization) string {
    mut args := []string{}

    for arg in node.args {
        args << gen.expr(arg)
    }

    return "{${args.join(", ")}}"
}

fn get_built_in_types() []string {
    return ["std::string", "int", "bool", "float", "char"]
}

// TODO add more built in types
fn is_built_in_type(type_name string) bool {
    return type_name in get_built_in_types()
}