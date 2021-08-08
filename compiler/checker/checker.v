module checker

import ast
import utils

pub struct Checker {
    ast ast.AST
mut:
    fns map[string]ast.FunctionDeclarationStatement
    structs map[string]ast.StructDeclarationStatement
    vars map[string]ast.VariableDecl
    mods []string
}

pub fn new(ast ast.AST) Checker {
    return Checker{
        ast,
        map[string]ast.FunctionDeclarationStatement,
        map[string]ast.StructDeclarationStatement{},
        map[string]ast.VariableDecl{},
        []string{}
    }
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
    } else if node is ast.StructDeclarationStatement {
        checker.structs[node.name] = node
    } else if node is ast.ModuleDeclarationStatement {
        if node.name != node.name.capitalize() {
            // utils.error("Module names must be capitalized, found: `$node.name`")
        }
        checker.mods << node.name
    }
}


fn (mut checker Checker) expr(node ast.Expr) {
    if node is ast.FunctionCallExpr {
        checker.fn_call(node)
    } else if node is ast.VariableDecl {
        checker.var_decl(node)
    }
}

fn (mut checker Checker) var_decl(node ast.VariableDecl) {
    if checker.vars.keys().contains(node.name) {
        var_type := checker.vars[node.name]
        // panic(var_type)
    }
    checker.vars[node.name] = node

    // checking the variable body
    for body in node.value {
        checker.check(body)
    }
}

fn (mut checker Checker) fn_call(node ast.FunctionCallExpr) {
    // panic(node)
}