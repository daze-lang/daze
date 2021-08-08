module codegen

import ast

pub struct CCodeGenerator {
pub:
    ast ast.AST

}

pub fn new_c(ast ast.AST) CCodeGenerator {
    return CCodeGenerator{ast}
}

pub fn (mut gen CCodeGenerator) run() string {
    mut code := "#include <stdio.h>\n#include <stdlib.h>\n\n"

    for node in gen.ast.nodes {
        code += gen.gen(node)
    }

    return code
}

pub fn (mut gen CCodeGenerator) gen(node ast.Node) string {
    mut code := ""

    if mut node is ast.Statement {
        code += gen.statement(node)
    } else if mut node is ast.Expr {
        code += gen.expr(node)
    }

    return code
}

fn (mut gen CCodeGenerator) statement(node ast.Statement) string {
    mut code := ""

    if mut node is ast.FunctionDeclarationStatement {
        code = gen.fn_decl(node)
    }

    return code
}

fn (mut gen CCodeGenerator) expr(node ast.Expr) string {
    mut code := ""
    if mut node is ast.StringLiteralExpr {
        code = "\"$node.value\""
    } else if mut node is ast.NumberLiteralExpr {
        code = node.value.str().replace(".", "")
    } else if mut node is ast.FunctionCallExpr {
        code = gen.fn_call(node)
    } else if mut node is ast.VariableExpr {
        code = node.value
    } else if mut node is ast.ReturnExpr {
        code = gen.return_expr(node)
    } else if mut node is ast.VariableDecl {
        code = gen.variable_decl(node)
    } else if mut node is ast.RawBinaryOpExpr {
        code = node.value
    } else if mut node is ast.IfExpression {
        code = gen.if_statement(node)
    } else if mut node is ast.ForLoopExpr {
        // code = gen.for_loop(node)
    } else if mut node is ast.ArrayDefinition {
        // code = gen.array(node)
    } else if mut node is ast.ArrayPushExpr {
        // code = "${node.target.replace("Self.", "@")} << ${gen.gen(node.value)}\n"
    } else if mut node is ast.IncrementExpr {
        code = "${node.target}++\n"
    } else if mut node is ast.DecrementExpr {
        code = "${node.target}--\n"
    } else if mut node is ast.ForInLoopExpr {
        // code = gen.for_in_loop(node)
    } else if mut node is ast.IndexingExpr {
        // code = gen.indexing(node)
    } else if mut node is ast.RawCrystalCodeExpr {
        // code = node.value
    } else if mut node is ast.GroupedExpr {
        code = gen.grouped_expr(node)
    }

    return code
}

fn (mut gen CCodeGenerator) fn_decl(node ast.FunctionDeclarationStatement) string {
    mut args := []string{}
    for arg in node.args {
        args << gen.fn_arg(arg)
    }

    args_str := if args.len == 0 { "void" } else { args.join(", ") }
    return_type := node.return_type.to_lower()
    mut code := "$return_type ${node.name}($args_str) {\n"
    for expr in node.body {
        code += gen.gen(expr)
    }

    code += "}\n\n"
    return code
}

fn (mut gen CCodeGenerator) fn_arg(node ast.FunctionArgument) string {
    return "${node.type_name.to_lower()} $node.name"
}

fn (mut gen CCodeGenerator) fn_call(node ast.FunctionCallExpr) string {
    mut args := []string{}
    for arg in node.args {
        args << gen.expr(arg).replace(";", "")
    }

    joined_args := args.join("")
    mut code := "${node.name}(${joined_args});\n"
    return code
}


fn (mut gen CCodeGenerator) return_expr(node ast.ReturnExpr) string {
    mut body := ""
    for expr in node.value {
        body += gen.gen(expr)
    }
    return "\nreturn ${body.replace("\n", " ").replace(";", "")};\n"
}

fn (mut gen CCodeGenerator) variable_decl(node ast.VariableDecl) string {
    mut body := ""
    for expr in node.value {
        body += "${gen.gen(expr)}"
    }

    return "${node.type_name.to_lower()} ${node.name} = ${body};\n"
}

fn (mut gen CCodeGenerator) if_statement(node ast.IfExpression) string {
    mut code := "if ${gen.expr(node.conditional)} {\n"
    for func in node.body {
        code += gen.gen(func)
    }

    if node.elseifs.len != 0 {
        for elsif in node.elseifs {
            code += "} else if ${gen.expr(elsif.conditional)} {\n"
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

fn (mut gen CCodeGenerator) grouped_expr(node ast.GroupedExpr) string {
    mut items := []string{}

    for item in node.body {
        items << gen.gen(item)
    }

    return "(${items.join(" ")})"
}