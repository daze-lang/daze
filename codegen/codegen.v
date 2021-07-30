module codegen

import ast

pub struct CodeGenerator {
pub:
    ast ast.AST
pub mut:
    mod string
    imports []string
}

pub fn (mut gen CodeGenerator) run() string {
    mut code := ""

    for node in gen.ast.nodes {
        code += gen.gen(node)
    }

    code = [
        "module ${gen.mod.capitalize()}",
        code,
        "end"
    ].join("\n")

    if gen.mod == "main" {
        code += "\nMain.main()"
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

    return code
}

fn (mut gen CodeGenerator) statement(node ast.Statement) string {
    // println("Generating statement")
    mut code := ""
    if mut node is ast.FunctionDeclarationStatement {
        code = gen.fn_decl(node)
    } else if mut node is ast.FunctionArgument {
        code = gen.fn_arg(node)
    } else if mut node is ast.StructDeclarationStatement {
        code = gen.struct_decl(node)
    } else if mut node is ast.ModuleDeclarationStatement {
        gen.set_module(node.name)
    } else if mut node is ast.ModuleUseStatement {
        gen.imports << node.path
    } else if mut node is ast.RawCrystalCodeStatement {
        code = node.value
    }

    return code
}

fn (mut gen CodeGenerator) expr(node ast.Expr) string {
    // println("Generating expr")
    mut code := ""
    if mut node is ast.StringLiteralExpr {
        code = gen.string_literal_expr(node)
    } else if mut node is ast.NumberLiteralExpr {
        code = gen.number_literal_expr(node)
    } else if mut node is ast.FunctionCallExpr {
        code = gen.fn_call(node)
    } else if mut node is ast.VariableExpr {
        code = gen.variable_expr(node)
    } else if mut node is ast.ReturnExpr {
        code = gen.return_expr(node)
    } else if mut node is ast.VariableDecl {
        code = gen.variable_decl(node)
    } else if mut node is ast.RawBinaryOpExpr {
        code = node.value
    }

    return code
}

fn (mut gen CodeGenerator) fn_decl(node ast.FunctionDeclarationStatement) string {
    mut args := []string{}
    for arg in node.args {
        args << gen.fn_arg(arg)
    }

    prefix := if node.name == "initialize" { "" } else { if node.is_struct { "" } else { "self." } }
    mut code := "def $prefix${node.name}(${args.join(", ")})\n"
    for expr in node.body {
        code += gen.gen(expr)
    }
    code += "end\n\n"

    return code
}

fn (mut gen CodeGenerator) fn_arg(node ast.FunctionArgument) string {
    typ := if node.type_name == "string" { "String" } else { node.type_name }
    return "$node.name : $typ?"
}

fn (mut gen CodeGenerator) fn_call(node ast.FunctionCallExpr) string {
    mut args := []string{}
    for arg in node.args {
        args << gen.expr(arg)
    }
    accessor := if node.name.contains(".") { "" } else {"self."}
    fn_name := if node.name == "out" { "puts" } else { "$accessor$node.name" }
    mut code := "${fn_name.replace("Self", "self")}(${args.join(", ")})\n"

    return code
}

fn (mut gen CodeGenerator) string_literal_expr(node ast.StringLiteralExpr) string {
    return '"$node.value"'
}

fn (mut gen CodeGenerator) number_literal_expr(node ast.NumberLiteralExpr) string {
    return node.value.str()
}

fn (mut gen CodeGenerator) variable_expr(node ast.VariableExpr) string {
    return node.value.replace("Self.", "@@") + "\n"
}

fn (mut gen CodeGenerator) return_expr(node ast.ReturnExpr) string {
    return "return ${gen.gen(node.value)}\n"
}

fn (mut gen CodeGenerator) variable_decl(node ast.VariableDecl) string {
    return "${node.name.replace("Self.", "@@")} = ${gen.gen(node.value)}"
}

fn (mut gen CodeGenerator) struct_decl(node ast.StructDeclarationStatement) string {
    mut code := "class ${node.name}\n"
    for arg in node.fields {
        code += "@@${gen.fn_arg(arg)}\n"
    }

    for func in node.fns {
        code += "${gen.fn_decl(func)}\n"
    }

    code += "end\n\n"

    return code
}

fn (mut gen CodeGenerator) set_module(name string) {
    gen.mod = name
}