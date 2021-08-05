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
            utils.error("Module names must be capitalized, found: `$node.name`")
        }
        checker.mods << node.name
    }
}


fn (mut checker Checker) expr(node ast.Expr) {
    if node is ast.FunctionCallExpr {
        checker.fn_call(node)
    } else if node is ast.VariableDecl {
        checker.vars[node.name] = node

        for body in node.value {
            checker.check(body)
        }
    }
}

fn (mut checker Checker) fn_call(node ast.FunctionCallExpr) {
    call_parts := node.name.split(".")
    mut check_against := ""

    // trying to access a module
    if checker.mods.contains(call_parts[0]) {
        // trying to access struct inside module
        if !checker.structs.keys().contains(call_parts[1]) && !checker.fns.keys().contains(call_parts[1]) {
            utils.error("Trying to access struct/function `${call_parts[1]}` in module `${call_parts[0]}`, but its undefined.")
        }
        check_against = call_parts[1]
    } else {
        // trying to call function defined in the current module
        if call_parts.len == 1 {
            if !checker.fns.keys().contains(call_parts[0]) {
                utils.error("Trying to call `${call_parts[0]}` but its undefined.")
            }
            check_against = call_parts[0]
        }
       // trying to access a variable
       println(checker.structs.keys())
       if !checker.vars.keys().contains(call_parts[0]) && !checker.structs.keys().contains(call_parts[0]) {
            if call_parts.len > 1 {
                utils.error("Trying to access variable `${call_parts[0]}`, but its undefined.")
            }
            check_against = call_parts[0]
       } else {
            // trying to call on variable
            if !checker.fns.keys().contains(call_parts[1]) && !checker.structs.keys().contains(call_parts[0]) {
                utils.error("Trying to call `${call_parts[1]}`, on `${call_parts[0]}` but its undefined.")
            }
            check_against = call_parts[1]
       }
    }

    calling_with_args := node.args
    fn_def_args := checker.fns[node.name].args

    // Checking argument count
    if calling_with_args.len < fn_def_args.len {
        utils.error("Too few arguments to call `$check_against`, got ${calling_with_args.len}, expected ${fn_def_args.len}.")
    } else if calling_with_args.len > fn_def_args.len {
        println(fn_def_args)
        utils.error("Too many arguments to call `$check_against`, got ${calling_with_args.len}, expected ${fn_def_args.len}.")
    }

    // checking argument types
    // panic(calling_with_args)
    for i, def_type in fn_def_args {
        arg := calling_with_args[i]
        type_str := utils.get_raw_type(arg)
        if type_str != def_type.type_name {
            if def_type.type_name != "Any" {
                utils.error("Argument `$def_type.name`, expects type ${def_type.type_name}, got ${type_str}.")
            }
        }
    }
}