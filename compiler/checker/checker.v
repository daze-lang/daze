module checker

import ast
import utils

pub struct Checker {
    ast ast.AST
mut:
    fns map[string]ast.FunctionDeclarationStatement
    mods []string
}

pub fn (mut checker Checker) run() {
    for node in checker.ast.nodes {
        checker.check(node)
    }
}


pub fn (mut checker Checker) check(node ast.Node) {
    if mut node is ast.Statement {
        checker.statement(node)
    } else if mut node is ast.Expr {
        checker.expr(node)
    }
}

fn (mut checker Checker) statement(node ast.Statement) {
    if node is ast.FunctionDeclarationStatement {
        checker.fns[node.name] = node
        for body in node.body {
            checker.check(body)
        }
    } else if node is ast.ModuleDeclarationStatement {
        if node.name != node.name.capitalize() {
            utils.error("Module names must be capitalized, found: `$node.name`")
        }
        checker.mods << node.name
    }
}


fn (mut checker Checker) expr(node ast.Expr) {
    if node is ast.FunctionCallExpr {
        checker.fn_call(node)
    }
}

fn (mut checker Checker) fn_call(node ast.FunctionCallExpr) {
    fn_name := if node.name.contains(".") {
        mod := node.name.split(".")[0]
        if !checker.mods.contains(mod) {
            utils.error("Trying to access undefined module: `$mod`")
        }
        node.name.split(".")[1]
    } else { node.name }

    if !checker.fns.keys().contains(fn_name) {
        utils.error("Calling undefined function: `$node.name`")
        return
    }
}