module checker

import ast{CompilationResult, Module}
import utils

pub struct Checker {
    ast ast.AST
mut:
    functions map[string]ast.FunctionDeclarationStatement
    structs map[string]ast.StructDeclarationStatement
    variables map[string]ast.VariableDecl
    modules map[string]CompilationResult
}

pub fn new(ast ast.AST, modules map[string]CompilationResult) Checker {
    return Checker{
        ast,
        map[string]ast.FunctionDeclarationStatement,
        map[string]ast.StructDeclarationStatement{},
        map[string]ast.VariableDecl{},
        modules
    }
}

pub fn (mut checker Checker) run() {
    for _, mod in checker.modules {
        for node in mod.ast.nodes {
            checker.check(node)
        }
    }

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
        checker.functions[node.name] = node
        for body in node.body {
            checker.check(body)
        }
    } else if node is ast.StructDeclarationStatement {
        checker.structs[node.name] = node
    } else if node is ast.ModuleDeclarationStatement {
        if node.name == node.name.capitalize() {
            utils.error("Module names must be lowercase, found: `$node.name`")
        }
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
    if checker.variables.keys().contains(node.name) {
        var_type := checker.variables[node.name]
    }

    cast := node.value[0]
    expected := node.type_name

    mut my_type := ""
    if cast is ast.StringLiteralExpr {
        my_type = "String"
    } else if cast is ast.NumberLiteralExpr {
        my_type = "Int"
    } else if cast is ast.FunctionCallExpr {
        my_type = checker.functions[resolve_function_name(cast.name)].return_type
    }

    if expected != my_type {
        panic("Type mismatch. Trying to assign ${my_type} to variable `${node.name}`, but it expects ${expected}")
    }

    checker.variables[node.name] = node

    // checking the variable body
    for body in node.value {
        checker.check(body)
    }
}

fn (mut checker Checker) fn_call(node ast.FunctionCallExpr) {
    mut function_name := resolve_function_name(node.name)
    if node.name.contains(":") {
        mut module_name := node.name.split(":")[0]
        function_name = node.name.split(":")[1]
        if !checker.modules.keys().contains(module_name) {
            panic("Referencing unknown module: ${module_name}")
        }
    }

    if !checker.functions.keys().contains(function_name) {
        panic("Trying to call unknown function: ${node.name}")
    }

    // Checking argument count
    ast_node := checker.functions[function_name]
    args_len := ast_node.args.len
    if node.args.len > args_len {
        panic("Too many arguments to call $function_name; got ${node.args.len}, expected ${args_len}")
    }

    if node.args.len < args_len {
        panic("Too few arguments to call $function_name; got ${node.args.len}, expected ${args_len}")
    }

    // Checking argument types
    for i in 0..args_len {
        expected := ast_node.args[i].type_name
        mut my_type := ""
        cast := node.args[i]
        if cast is ast.StringLiteralExpr {
            my_type = "String"
        } else if cast is ast.NumberLiteralExpr {
            my_type = "Int"
        } else if cast is ast.FunctionCallExpr {
            my_type = checker.functions[resolve_function_name(cast.name)].return_type
        }
        if expected != my_type {
            panic("Type mismatch. Trying to call function `$function_name` with argument `${ast_node.args[i].name}` as ${my_type}, but it expects ${expected}")
        }
    }
}

fn resolve_function_name(name string) string {
    mut function_name := name
    if name.contains(":") {
        function_name = name.split(":")[1]
    }
    return function_name
}