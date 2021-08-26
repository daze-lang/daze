module checker

import ast{CompilationResult, Module}
import utils

pub struct Checker {
    ast ast.AST
mut:
    functions map[string]ast.FunctionDeclarationStatement
    structs map[string]ast.StructDeclarationStatement
    variables map[string]map[string]ast.VariableDecl
    enums map[string]ast.EnumDeclarationStatement
    modules map[string]CompilationResult
    current_mod string
    current_fn string
}

pub fn new(ast ast.AST, modules map[string]CompilationResult) Checker {
    return Checker{
        ast,
        map[string]ast.FunctionDeclarationStatement,
        map[string]ast.StructDeclarationStatement{},
        map[string]map[string]ast.VariableDecl{},
        map[string]ast.EnumDeclarationStatement,
        modules,
        "",
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
        checker.current_fn = node.name
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
    } else if node is ast.EnumDeclarationStatement {
        checker.enums[node.name] = node
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
    } else if node is ast.OptionalFunctionCall {
        checker.optional(node)
    } else if node is ast.VariableAssignment {
        checker.var_assignment(node)
    } else if node is ast.VariableExpr {
        if !checker.variables.keys().contains(node.value) && !checker.enums.keys().contains(node.value.split(":")[0])  {
            // TODO: proper error message
            // TODO: check dot operator accessing here
            if node.value.contains(".") {
                checker.dotchain(node.value.split("."))
            }
            panic("Accessing unknown variable: ${node.value}")
        }

        if node.value.contains(":") {
            // module or enum
            mod_or_enum_name := node.value.split(":")[0]
            field := node.value.split(":")[1]
            is_mod := checker.modules.keys().contains(mod_or_enum_name)
            is_enum := checker.enums.keys().contains(mod_or_enum_name)

            if is_enum {
                if !checker.enums[mod_or_enum_name].values.contains(field) {
                    panic("Trying to access unkown field ${field} of enum `${mod_or_enum_name}`")
                }
            }

            if is_mod {
                panic("Unhandled: checker.v:109")
            }
        }
    }
}

fn (mut checker Checker) var_decl(node ast.VariableDecl) {
    checker.check(node.value)
    if node.value is ast.NoOp {
        return
    }
    expected := node.type_name.replace("::", ":").replace("ref ", "")
    my_type := checker.infer(node.value)

    if expected != my_type {
        panic("Type mismatch. Trying to assign ${my_type} to variable `${node.name}`, but it expects ${expected}")
    }

    checker.variables[checker.current_fn][node.name] = node

    // checking the variable body
    checker.check(node.value)
}

fn (mut checker Checker) fn_call(node ast.FunctionCallExpr) {
    mut function_name := resolve_function_name(node.name)
    for arg in node.args {
        checker.check(arg)
    }

    if function_name == "main" {
        panic("Calling `main` is not allowed.")
    }

    // Allowing println for now
    if function_name == "println" {
        // panic(checker.variables)
        return
    }

    if node.name.contains(":") {
        mut module_name := node.name.split(":")[0]
        function_name = node.name.split(":")[1]
        if !checker.modules.keys().contains(module_name) {
            // panic("Referencing unknown module: ${module_name}")
        }
    }

    if !checker.functions.keys().contains(function_name) {
        // calling on a variable
        if node.name.contains(".") {
            variable := node.name.split(".")[0]
            fn_name := node.name.split(".")[1]
            var_type := checker.variables[checker.current_fn][variable].type_name
            if !checker.struct_has_function_by_name(var_type.replace("::", ":"), fn_name) {
                panic("Trying to call unknown function: ${node.name}")
            }
        } else {
            panic("Trying to call unknown function: ${node.name}")
        }
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
        expected := ast_node.args[i].type_name.replace("ref ", "")
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

fn (mut checker Checker) optional(node ast.OptionalFunctionCall) {
    checker.check(node.fn_call)
    type_name := checker.infer(node.fn_call).replace("?", "")
    if type_name != checker.infer(node.default) {
        // TODO
        panic("Optional function call & default value types don't match.")
    }
}

fn (mut checker Checker) var_assignment(node ast.VariableAssignment) {
    mut expected := "UNKNOWN"
    if !checker.variables[checker.current_fn].keys().contains(node.name) {
        if checker.fn_has_arg_with_name(checker.current_fn, node.name) {
            expected = checker.fn_get_arg_with_name(checker.current_fn, node.name).type_name.replace("ref ", "")
        } else if node.name.contains(".") {
            // assigning to struct field
            var_name := node.name.split(".")[0]
            struct_field := node.name.split(".")[1]
            if !checker.fn_has_arg_with_name(checker.current_fn, var_name) {
                panic("Trying to assign to unknown struct variable `$var_name` in function `$checker.current_fn`")
            }
            arg_type := checker.fn_get_arg_with_name(checker.current_fn, var_name).type_name.replace("ref ", "")
            expected = checker.get_struct_field_by_name(arg_type, struct_field).type_name
        } else {
            panic("Trying to assign to unknown variable `$node.name` in function `$checker.current_fn`")
        }

    } else {
        expected = checker.infer(checker.variables[checker.current_fn][node.name].value)
    }

    checker.check(node.value)
    my_type := checker.infer(node.value)

    if expected != my_type {
        panic("Type mismatch. Trying to assign ${my_type} to variable `${node.name}`, but it expects ${expected}")
    }

    // checking the variable body
    checker.check(node.value)
}

fn (mut checker Checker) dotchain(chain []string) {
    mut checked := []string{}
    for var in chain {
        is_variable := checker.variables[checker.current_fn].keys().contains(var)
        panic(is_variable)
    }
}

// Type Inference

fn (mut checker Checker) infer(node ast.Expr) string {
    mut type_name := ""
    if node is ast.BinaryOperation {
        type_name = checker.infer(node.lhs)
    } else if node is ast.OptionalFunctionCall {
        type_name = checker.infer(node.fn_call)
    } else if node is ast.MapInit {
        type_name = "${checker.infer(node.body[0].key)}->${checker.infer(node.body[0].value)}"
    } else if node is ast.FunctionCallExpr {
        type_name = checker.functions[resolve_function_name(node.name)].return_type.replace("?", "")
    } else if node is ast.StringLiteralExpr {
        type_name = "String"
    } else if node is ast.NumberLiteralExpr {
        type_name = "Int"
    } else if node is ast.StructInitialization {
        type_name = node.name
    } else if node is ast.TypeCast {
        type_name = node.type_name
    } else if node is ast.VariableExpr {
        // accessing struct field
        if node.value.contains(".") {
            checker.dotchain(node.value.split("."))
        } else {
            if checker.variables[checker.current_fn][node.value].type_name == "" {
                enum_name := node.value.split(":")[0]
                if checker.enums.keys().contains(enum_name) {
                    type_name = enum_name
                }
            }
            type_name = checker.variables[checker.current_fn][node.value].type_name
        }
    }
    if type_name == "" {
        panic("Unable to infer type: $node")
    }

    return type_name.replace("ref ", "")
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

fn (mut checker Checker) get_struct_function_by_name(struct_name string, fn_name string) ast.FunctionDeclarationStatement {
    for memberfn in checker.structs[struct_name].member_fns {
        if memberfn.name == fn_name {
            return memberfn
        }
    }

    // Should be unreachable
    return ast.FunctionDeclarationStatement{}
}

fn (mut checker Checker) struct_has_function_by_name(struct_name string, fn_name string) bool {
    for memberfn in checker.structs[struct_name].member_fns {
        if memberfn.name == fn_name {
            return true
        }
    }

    // Should be unreachable
    return false
}

fn (mut checker Checker) fn_has_arg_with_name(fn_name string, arg_name string) bool {
    for arg in checker.functions[fn_name].args {
        if arg.name == arg_name {
            return true
        }
    }

    // should be unreachable
    return false
}

fn (mut checker Checker) fn_get_arg_with_name(fn_name string, arg_name string) ast.FunctionArgument {
    for arg in checker.functions[fn_name].args {
        if arg.name == arg_name {
            return arg
        }
    }

    // should be unreachable
    return ast.FunctionArgument{}
}

fn resolve_function_name(name string) string {
    mut function_name := name
    if name.contains(":") {
        function_name = name.split(":")[1]
    }
    return function_name
}