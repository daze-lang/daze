module codegen

import ast

pub struct CrystalCodeGenerator {
pub:
    ast ast.AST
pub mut:
    mod_count int
    mods []string
    c int
}

pub fn new_crystal(ast ast.AST) CrystalCodeGenerator {
    return CrystalCodeGenerator{ast, 0, []string{}, 0}
}

pub fn (mut gen CrystalCodeGenerator) run() string {
    mut code := ""

    for node in gen.ast.nodes {
        code += gen.gen(node)
    }

    code += "\nend\nMain.main()".trim_space()
    return code.trim_left("end")
}

pub fn (mut gen CrystalCodeGenerator) gen(node ast.Node) string {
    mut code := ""

    if mut node is ast.Statement {
        code += gen.statement(node)
    } else if mut node is ast.Expr {
        code += gen.expr(node)
    }

    return code
}

fn (mut gen CrystalCodeGenerator) statement(node ast.Statement) string {
    mut code := ""
    if mut node is ast.FunctionDeclarationStatement {
        code = gen.fn_decl(node)
    } else if mut node is ast.FunctionArgument {
        code = gen.fn_arg(node)
    } else if mut node is ast.ModuleDeclarationStatement {
        code = "end\nmodule $node.name\nextend self\n"
        gen.mods << node.name
        gen.mod_count++
    } else if mut node is ast.StructDeclarationStatement {
        code = gen.struct_decl(node)
    } else if mut node is ast.RawCrystalCodeStatement {
        code = node.value
    } else if mut node is ast.ModuleUseStatement {
        code = "include ${node.path.replace("daze::", "")}\n"
    }

    return code
}

fn (mut gen CrystalCodeGenerator) expr(node ast.Expr) string {
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
    } else if mut node is ast.IfExpression {
        code = gen.if_statement(node)
    } else if mut node is ast.ForLoopExpr {
        code = gen.for_loop(node)
    } else if mut node is ast.ArrayDefinition {
        code = gen.array(node)
    } else if mut node is ast.ArrayPushExpr {
        code = "${node.target.replace("Self.", "@")} << ${gen.gen(node.value)}\n"
    } else if mut node is ast.IncrementExpr {
        code = "${node.target.replace("Self.", "@")} += 1\n"
    } else if mut node is ast.DecrementExpr {
        code = "${node.target.replace("Self.", "@")} -= 1\n"
    } else if mut node is ast.ForInLoopExpr {
        code = gen.for_in_loop(node)
    } else if mut node is ast.IndexingExpr {
        code = gen.indexing(node)
    } else if mut node is ast.RawCrystalCodeExpr {
        code = node.value
    } else if mut node is ast.GroupedExpr {
        code = gen.grouped_expr(node)
    }

    return code
}

fn (mut gen CrystalCodeGenerator) fn_decl(node ast.FunctionDeclarationStatement) string {
    mut args := []string{}
    for arg in node.args {
        args << gen.fn_arg(arg)
    }
    suffix := if node.gen_type != "" { " forall $node.gen_type" } else { "" }
    prefix := if node.name == "initialize" { "" } else { if node.is_struct { "" } else { "" } }
    mut code := "def $prefix${node.name}(${args.join(", ")})$suffix\n"
    for expr in node.body {
        code += gen.gen(expr)
    }
    code += "end\n\n"

    return code
}

fn (mut gen CrystalCodeGenerator) fn_arg(node ast.FunctionArgument) string {
    typ := if node.type_name == "string" { "String" } else { node.type_name }
    if node.type_name == "Any" {
        return "$node.name"
    }

    return "$node.name : $typ"
}

fn (mut gen CrystalCodeGenerator) fn_call(node ast.FunctionCallExpr) string {
    mut args := []string{}
    for arg in node.args {
        args << gen.expr(arg)
    }

    accessor := if node.name.contains(".") { "" } else {""}
    type_data := if node.gen_type != "" { "($node.gen_type)" } else { "" }
    mut fn_name := "$accessor$node.name"
    if fn_name.contains(".new") {
        fn_name_without_new := fn_name.replace(".new", "")
        fn_name = "${fn_name_without_new}${type_data}.new"
    }

    if node.name.starts_with("@") {
        fn_name = node.name.replace("@", "")
    }

    if gen.mods.contains(fn_name.split(".")[0]) && fn_name.split(".").len > 2 {
        fn_name = fn_name.replace_once(".", "::")
    }
    mut code := "\n${fn_name.replace("Self", "self")}(${args.join("")})"
    return code
}

fn (mut gen CrystalCodeGenerator) string_literal_expr(node ast.StringLiteralExpr) string {
    val := node.value.replace("Self.", "@")
    return "\"$val\""
}

fn (mut gen CrystalCodeGenerator) number_literal_expr(node ast.NumberLiteralExpr) string {
    return "$node.value"
}

fn (mut gen CrystalCodeGenerator) variable_expr(node ast.VariableExpr) string {
    if node.value == "===" {
        return " ${node.value.replace("Self.", "@")} "
    }
    return node.value.replace("Self.", "@")
}

fn (mut gen CrystalCodeGenerator) return_expr(node ast.ReturnExpr) string {
    mut body := ""
    for expr in node.value {
        body += gen.gen(expr)
    }
    return "\nreturn ${body.replace("\n", " ")}\n"
}

fn (mut gen CrystalCodeGenerator) variable_decl(node ast.VariableDecl) string {
    mut body := ""
    for expr in node.value {
        body += "${gen.gen(expr)} "
    }

    if node.type_name != "" {
        return "\n${node.name.replace("Self.", "@")} : $node.type_name = ${body}\n"
    } else {
        return "\n${node.name.replace("Self.", "@")} = ${body}\n"
    }
}

fn (mut gen CrystalCodeGenerator) struct_decl(node ast.StructDeclarationStatement) string {
    generic_type := if node.gen_type != "" { "($node.gen_type)" } else { "" }
    mut code := "struct ${node.name}$generic_type\n"

    for func in node.fns {
        code += "${gen.fn_decl(func)}\n"
    }

    code += "end\n\n"

    return code
}

fn (mut gen CrystalCodeGenerator) set_module(name string) {
    // gen.mod = name
}

fn (mut gen CrystalCodeGenerator) if_statement(node ast.IfExpression) string {
    mut code := "if ${gen.expr(node.conditional)}\n"
    for func in node.body {
        code += gen.gen(func)
    }

    if node.elseifs.len != 0 {
        for elsif in node.elseifs {
            code += " elsif ${gen.expr(elsif.conditional)}\n"
            for func in elsif.body {
                code += gen.gen(func)
            }
        }
    }

    if node.else_branch.len != 0 {
        code += " else\n"
        for func in node.else_branch {
            code += gen.gen(func)
        }
    }

    code += "end\n"
    return code
}

fn (mut gen CrystalCodeGenerator) for_loop(node ast.ForLoopExpr) string {
    mut code := "\nwhile ${gen.gen(node.conditional)}\n"
    for func in node.body {
        code += gen.gen(func) + "\n"
    }
    code += "end\n"
    return code
}

fn (mut gen CrystalCodeGenerator) for_in_loop(node ast.ForInLoopExpr) string {
    gen.c++
    vardecl := "for_in_loop${gen.c} = ${gen.gen(node.target).split("of")[0]}"
    mut code := "\n$vardecl\nfor_in_loop${gen.c}.each_index do |index|\n$node.container = for_in_loop${gen.c}[index]\n"
    for func in node.body {
        code += gen.gen(func) + "\n"
    }
    code += "end\n"
    return code
}

fn (mut gen CrystalCodeGenerator) array(node ast.ArrayDefinition) string {
    mut code := "["
    mut items := []string{}

    for item in node.items {
        items << gen.gen(item)
    }

    code += "${items.join(", ")}] of $node.type_name"
    return code
}

fn (mut gen CrystalCodeGenerator) indexing(node ast.IndexingExpr) string {
    return "${node.var.replace("Self.", "@")}[${gen.gen(node.body)}]"
}

fn (mut gen CrystalCodeGenerator) grouped_expr(node ast.GroupedExpr) string {
    mut items := []string{}

    for item in node.body {
        items << gen.gen(item)
    }

    return "(${items.join(" ")})"
}