module codegen

import ast

pub struct CodeGenerator {
pub:
    ast ast.AST
}

pub fn (mut gen CodeGenerator) run() string {
    mut code := ""

    for node in gen.ast.nodes {
        code += gen.gen(node)
    }

    return code
}

pub fn (mut gen CodeGenerator) gen(node ast.Node) string {
    mut code := ""

    if mut node is ast.Statement {
        code += gen.statement(node)
    } else if mut node is ast.Expr {
        code += gen.expr(node)
    }

    // if mut node is ast.FunctionDeclarationStatement {
    //     code = gen.fn_decl(node)
    // } else if mut node is ast.StringLiteralExpr {
    //     code = gen.string_literal_expr(node)
    // }

    return code
}

fn (mut gen CodeGenerator) statement(node ast.Statement) string {
    // println("Generating statement")
    mut code := ""
    if mut node is ast.FunctionDeclarationStatement {
        code = gen.fn_decl(node)
    }

    return code
}

fn (mut gen CodeGenerator) expr(node ast.Expr) string {
    // println("Generating expr")
    mut code := ""
    if mut node is ast.StringLiteralExpr {
        code = gen.string_literal_expr(node)
    } else if mut node is ast.FunctionCallExpr {
        code = gen.fn_call(node)
    }

    return code
}

fn (mut gen CodeGenerator) fn_decl(node ast.FunctionDeclarationStatement) string {
    mut code := "def ${node.name}()\n"
    code += gen.gen(node.body)
    code += "end\n\n"

    return code
}

fn (mut gen CodeGenerator) fn_call(node ast.FunctionCallExpr) string {
    fn_name := if node.name == "out" { "puts" } else { node.name }
    mut code := "${fn_name}(${gen.gen(node.args)})\n"

    return code
}

fn (mut gen CodeGenerator) string_literal_expr(node ast.StringLiteralExpr) string {
    return '"$node.value"'
}