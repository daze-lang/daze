module codegen

import ast

pub struct CodeGenerator {
pub:
    ast ast.AST
pub mut:
    mod_count int
}

pub fn (mut gen CodeGenerator) run() string {
    mut code := ""

    for node in gen.ast.nodes {
        code += gen.gen(node)
    }

    // code += "end\n".repeat(gen.mod_count)
    code += "\nend\nMain.main()"
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
        prefix := if gen.mod_count > 0 {"\nend\n"} else {""}
        code = "${prefix}module $node.name\n"
        gen.mod_count++
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
    } else if mut node is ast.IfExpression {
        code = gen.if_statement(node)
    } else if mut node is ast.ForLoopExpr {
        code = gen.for_loop(node)
    } else if mut node is ast.ArrayDefinition {
        code = gen.array(node)
    } else if mut node is ast.ArrayPushExpr {
        code = "$node.target << ${gen.gen(node.value)}\n"
    } else if mut node is ast.IncrementExpr {
        code = "$node.target += 1\n"
    } else if mut node is ast.DecrementExpr {
        code = "$node.target -= 1\n"
    } else if mut node is ast.ForInLoopExpr {
        code = gen.for_in_loop(node)
    } else if mut node is ast.IndexingExpr {
        code = gen.indexing(node)
    } else if mut node is ast.RawCrystalCodeExpr {
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
    if node.type_name == "Any" {
        return "$node.name"
    }

    return "$node.name : $typ?"
}

fn (mut gen CodeGenerator) fn_call(node ast.FunctionCallExpr) string {
    mut args := []string{}
    for arg in node.args {
        args << gen.expr(arg)
    }
    accessor := if node.name.contains(".") { "" } else {"self."}
    fn_name := "$accessor$node.name"
    mut code := "${fn_name.replace("Self", "self")}(${args.join(", ")})\n"

    return code
}

fn (mut gen CodeGenerator) string_literal_expr(node ast.StringLiteralExpr) string {
    val := node.value.replace("Self.", "@")
    return "DazeString.new(\"$val\")"
    // return "\"${node.value.replace("Self.", "@")}\""
}

fn (mut gen CodeGenerator) number_literal_expr(node ast.NumberLiteralExpr) string {
    return node.value.str()
}

fn (mut gen CodeGenerator) variable_expr(node ast.VariableExpr) string {
    return node.value.replace("Self.", "@") + "\n"
}

fn (mut gen CodeGenerator) return_expr(node ast.ReturnExpr) string {
    return "return ${gen.gen(node.value)}\n"
}

fn (mut gen CodeGenerator) variable_decl(node ast.VariableDecl) string {
    return "${node.name.replace("Self.", "@")} = ${gen.gen(node.value)}\n"
}

fn (mut gen CodeGenerator) struct_decl(node ast.StructDeclarationStatement) string {
    mut code := "class ${node.name}\n"
    for arg in node.fields {
        code += "@${gen.fn_arg(arg)}\n"
    }

    for func in node.fns {
        code += "${gen.fn_decl(func)}\n"
    }

    code += "end\n\n"

    return code
}

fn (mut gen CodeGenerator) set_module(name string) {
    // gen.mod = name
}

fn (mut gen CodeGenerator) if_statement(node ast.IfExpression) string {
    mut code := "if ${gen.expr(node.conditional)}\n"
    for func in node.body {
        code += gen.gen(func)
    }

    if node.elseifs.len != 0 {
        for elsif in node.elseifs {
            code += "elsif ${gen.expr(elsif.conditional)}\n"
            for func in elsif.body {
                code += gen.gen(func)
            }
        }
    }

    if node.else_branch.len != 0 {
        code += "else\n"
        for func in node.else_branch {
            code += gen.gen(func)
        }
    }

    code += "end\n"
    return code
}

fn (mut gen CodeGenerator) for_loop(node ast.ForLoopExpr) string {
    mut code := "while ${gen.gen(node.conditional)}\n"
    for func in node.body {
        code += gen.gen(func) + "\n"
    }
    code += "end\n"
    return code
}

fn (mut gen CodeGenerator) for_in_loop(node ast.ForInLoopExpr) string {
    mut code := "${node.target}.each_index do |index|\n$node.container = ${node.target}[index]\n"
    for func in node.body {
        code += gen.gen(func) + "\n"
    }
    code += "end\n"
    return code
}

fn (mut gen CodeGenerator) array(node ast.ArrayDefinition) string {
    mut code := "["
    mut items := []string{}

    for item in node.items {
        items << gen.gen(item)
    }

    code += "${items.join(", ")}] of $node.type_name"
    return code
}

fn (mut gen CodeGenerator) indexing(node ast.IndexingExpr) string {
    return "$node.var[${gen.gen(node.body)}]"
}