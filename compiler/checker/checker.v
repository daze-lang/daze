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
    current_mod string
}

pub fn new(ast ast.AST, modules map[string]CompilationResult) Checker {
    return Checker{
        ast,
        map[string]ast.FunctionDeclarationStatement,
        map[string]ast.StructDeclarationStatement{},
        map[string]ast.VariableDecl{},
        modules,
        ""
    }
}

pub fn (mut checker Checker) run() {
    for modname, mod in checker.modules {
        checker.current_mod = modname
        for node in mod.ast.nodes {
            checker.check(node)
        }
    }

    checker.current_mod = "main"
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
        if checker.current_mod != "main" {
            checker.structs[checker.current_mod + ":" + node.name] = node
        } else {
            checker.structs[node.name] = node
        }
    } else if node is ast.GlobalDecl {
        if node.name != node.name.capitalize() {
            utils.error("Global variable names must be uppercase, found: `$node.name`")
        }
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
    } else if node is ast.StructInitialization {
        checker.struct_decl(node)
    } else if node is ast.BinaryOperation {
        checker.binary(node)
    } else if node is ast.VariableExpr {
        if !checker.variables.keys().contains(node.value) {
            // TODO: proper error message
            panic("Accessing unknown variable")
        }
    }
}

fn (mut checker Checker) var_decl(node ast.VariableDecl) {
    checker.check(node.value)
    expected := node.type_name.replace("::", ":")
    my_type := checker.infer(node.value)

    if expected != my_type {
        panic("Type mismatch. Trying to assign ${my_type} to variable `${node.name}`, but it expects ${expected}")
    }

    checker.variables[node.name] = node

    // checking the variable body
    checker.check(node.value)
}

fn (mut checker Checker) fn_call(node ast.FunctionCallExpr) {
    mut function_name := resolve_function_name(node.name)

    if function_name == "main" {
        panic("Calling `main` is not allowed.")
    }

    // Allowing println for now
    if function_name == "println" {
        return
    }

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
        checker.check(node.args[i])
        expected := ast_node.args[i].type_name
        my_type := checker.infer(node.args[i])

        if expected != my_type {
            panic("Type mismatch. Trying to call function `$function_name` with argument `${ast_node.args[i].name}` as ${my_type}, but it expects ${expected}")
        }
    }
}

fn (mut checker Checker) struct_decl(node ast.StructInitialization) {
    args_len := node.args.len
    ast_node := checker.structs[node.name]
    // Checking argument types
    for i in 0..args_len {
        checker.check(node.args[i])
        expected := ast_node.fields[i].type_name
        my_type := checker.infer(node.args[i])

        if expected != my_type {
            panic("Type mismatch: Trying to assign ${my_type} to ${node.name}.${ast_node.fields[i].name}, but it expects $expected")
        }
    }
}

fn (mut checker Checker) array_init(expected_type string, node ast.ArrayInit) {
    expected := expected_type.split("|")[0]
    // // Checking argument types
    for i in 0..node.body.len {
        my_type := checker.infer(node.body[i])
        checker.check(node.body[i])

        if expected != my_type {
            // TODO: proper error message
            panic("Type mismatch")
        }
    }
}

fn (mut checker Checker) binary(node ast.BinaryOperation) {
    checker.check(node.lhs)
    checker.check(node.rhs)

    if checker.infer(node.lhs) != checker.infer(node.rhs) {
        panic("Type mismatch in binary. Got: ${checker.infer(node.rhs)}, expected: ${checker.infer(node.lhs)}")
    }

    if node.lhs is ast.BinaryOperation {
        checker.binary(node.lhs)
    }

    if node.rhs is ast.BinaryOperation {
        checker.binary(node.rhs)
    }
}

// Type Inference

fn (mut checker Checker) infer(node ast.Expr) string {
    if node is ast.BinaryOperation {
        return checker.infer(node.lhs)
    } else if node is ast.FunctionCallExpr {
        return checker.functions[resolve_function_name(node.name)].return_type
    } else if node is ast.StringLiteralExpr {
        return "String"
    } else if node is ast.NumberLiteralExpr {
        return "Int"
    } else if node is ast.StructInitialization {
        return node.name
    } else if node is ast.VariableExpr {
        // accessing struct field
        if node.value.contains(".") {
            calling_on := node.value.split(".")[0]
            field := node.value.split(".")[1]
            struct_name := checker.variables[calling_on].type_name
            return checker.get_struct_field_by_name(struct_name, field).type_name
        } else {
            return checker.variables[node.value].type_name
        }
    }

    panic("Unable to infer type: $node")
}

// Utilities

fn (mut checker Checker) get_struct_field_by_name(struct_name string, field_name string) ast.FunctionArgument {
    for field in checker.structs[struct_name].fields {
        if field.name == field_name {
            return field
        }
    }

    // Should be unreachable
    return ast.FunctionArgument{}
}

fn resolve_function_name(name string) string {
    mut function_name := name
    if name.contains(":") {
        function_name = name.split(":")[1]
    }
    return function_name
}