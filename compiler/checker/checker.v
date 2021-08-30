module checker

import ast{CompilationResult, Module}
import utils

pub struct Checker {
    ast ast.AST
mut:
    // list of modules, key: module name
    modules map[string]CompilationResult
    // the current module we are inside (can be deprecated in favor of checker.context.mod_name)
    current_mod string
    // the current function name we inside
    current_fn string
    // Points to the current context, every file that is imported is a unique context
    context Context
    // map of contexts; key: module name
    contexts map[string]Context
}

struct Context {
mut:
    mod_name string
    // map of function declarations inside the current module; key: function name
    functions map[string]ast.FunctionDeclarationStatement
    // map of struct declarations inside the current module; key: struct name
    structs map[string]ast.StructDeclarationStatement
    // map of function name -> variable name -> variable declaration ast node
    variables map[string]map[string]ast.VariableDecl
    // map of enum declarations inside the current module; key: enum name
    enums map[string]ast.EnumDeclarationStatement
}

fn new_context(modname string) Context {
    return Context{
        mod_name: modname,
        functions: map[string]ast.FunctionDeclarationStatement,
        structs: map[string]ast.StructDeclarationStatement{},
        variables: map[string]map[string]ast.VariableDecl{},
        enums: map[string]ast.EnumDeclarationStatement,
    }
}

pub fn new(ast ast.AST, modules map[string]CompilationResult) Checker {
    return Checker{
        ast: ast,
        modules: modules,
        current_mod: "",
        current_fn: "",
        context: Context{},
        contexts: map[string]Context{},
    }
}

pub fn (mut checker Checker) run() {
    // when we initialize the type checker, it first goes through every imported module
    // and typechecks them in an isolated space
    for modname, mod in checker.modules {
        checker.current_mod = modname
        for node in mod.ast.nodes {
            checker.check(node)
        }
    }

    // when we get to the main module, we set it as the current module and start the type checker
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
        if checker.context.functions.keys().contains(node.name) {
            panic("Fn already defined.")
        }
        checker.context.functions[node.name] = node

        // pushing arguments as variables for a function declaration
        for arg in node.args {
            arg_as_var := ast.VariableDecl{
                name: arg.name
                value: ast.Expr{}
                type_name: arg.type_name
            }
            checker.context.variables[checker.current_fn][arg.name] = arg_as_var
        }

        for body in node.body {
            checker.check(body)
        }
    } else if node is ast.StructDeclarationStatement {
        if checker.current_mod != "main" {
            checker.context.structs[checker.current_mod + ":" + node.name] = node
        } else {
            checker.context.structs[node.name] = node
        }
    } else if node is ast.EnumDeclarationStatement {
        checker.context.enums[node.name] = node
    } else if node is ast.GlobalDecl {
        if node.name != node.name.capitalize() {
            utils.error("Global variable names must be uppercase, found: `$node.name`")
        }
    } else if node is ast.ModuleDeclarationStatement {
        if node.name == node.name.capitalize() {
            utils.error("Module names must be lowercase, found: `$node.name`")
        }
        // creating new context when a new module use statement is found
        context := new_context(node.name)
        checker.contexts[checker.context.mod_name] = checker.context
        checker.context = context
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
        if !checker.context.variables[checker.current_fn].keys().contains(node.value) && !checker.context.enums.keys().contains(node.value.split(":")[0])  {
            // TODO: proper error message
            // TODO: check dot operator accessing here
            if node.value.contains(".") {
                checker.dotchain(node.value.split("."))
            }

            if node.value !in ["true", "false"] {
                panic("Accessing unknown variable: ${node.value}")
            }
        }

        if node.value.contains(":") {
            // module or enum
            mod_or_enum_name := node.value.split(":")[0]
            field := node.value.split(":")[1]
            is_mod := checker.modules.keys().contains(mod_or_enum_name)
            is_enum := checker.context.enums.keys().contains(mod_or_enum_name)

            if is_enum {
                if !checker.context.enums[mod_or_enum_name].values.contains(field) {
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

    checker.context.variables[checker.current_fn][node.name] = node

    // checking the variable body
    checker.check(node.value)
}

fn (mut checker Checker) fn_call(node ast.FunctionCallExpr) {
    mut mod_name, mut function_name := resolve_function_name(node.name)
    fn_node := checker.get_function_node_by_name(mod_name, function_name)

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

    if mod_name != "" {
        if !checker.modules.keys().contains(mod_name) {
            panic("Referencing unknown module: ${mod_name}")
        }
    }

    // if !checker.context.functions.keys().contains(function_name) {
    //     // calling on a variable
    //     if node.name.contains(".") {
    //         variable := node.name.split(".")[0]
    //         fn_name := node.name.split(".")[1]
    //         var_type := checker.context.variables[checker.current_fn][variable].type_name
    //         if !checker.struct_has_function_by_name(var_type.replace("::", ":"), fn_name) {
    //             panic("Trying to call unknown function: ${node.name}")
    //         }
    //     } else if node.name.contains(":") {
    //         mod := node.name.split(":")[0]
    //         fn_name := node.name.split(":")[1]
    //         if !checker.contexts.keys().contains(mod) {
    //             panic("Referencing unknown module: ${mod}")
    //         }
    //     } else {
    //         panic("Trying to call unknown function: ${node.name}")
    //     }
    // }

    // Checking argument count
    args_len := fn_node.args.len
    if node.args.len > args_len {
        panic("Too many arguments to call $function_name; got ${node.args.len}, expected ${args_len}")
    }

    if node.args.len < args_len {
        panic("Too few arguments to call $function_name; got ${node.args.len}, expected ${args_len}")
    }

    // Checking argument types
    for i in 0..args_len {
        checker.check(node.args[i])
        expected := fn_node.args[i].type_name.replace("ref ", "")
        my_type := checker.infer(node.args[i])

        if expected == "Any" {
            return
        }

        if expected != my_type {
            panic("Type mismatch. Trying to call function `$function_name` with argument `${fn_node.args[i].name}` as ${my_type}, but it expects ${expected}")
        }
    }
}

fn (mut checker Checker) struct_decl(node ast.StructInitialization) {
    args_len := node.args.len
    ast_node := checker.context.structs[node.name]
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
    if !checker.context.variables[checker.current_fn].keys().contains(node.name) {
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
        expected = checker.infer(checker.context.variables[checker.current_fn][node.name].value)
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
    for var in chain {
        is_variable := checker.context.variables[checker.current_fn].keys().contains(var)
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
        mod, fn_name := resolve_function_name(node.name)

        if mod != "" {
            return checker.get_function_node_by_name(mod, fn_name).return_type.replace("?", "")
        }

        type_name = checker.context.functions[fn_name].return_type.replace("?", "")
        if type_name == "" {
            return checker.resolve_callchain_to_fn(node.callchain).return_type
        }
    } else if node is ast.StringLiteralExpr {
        type_name = "String"
    } else if node is ast.NumberLiteralExpr {
        type_name = "Int"
    } else if node is ast.StructInitialization {
        type_name = node.name
    } else if node is ast.TypeCast {
        type_name = node.type_name
    } else if node is ast.VariableDecl {
        type_name = node.type_name.replace("::", ":")
    } else if node is ast.VariableExpr {
        // accessing struct field
        if node.value.contains(".") {
            checker.dotchain(node.value.split("."))
        } else {
            if checker.context.variables[checker.current_fn][node.value].type_name == "" {
                enum_name := node.value.split(":")[0]
                if checker.context.enums.keys().contains(enum_name) {
                    type_name = enum_name
                }
            }
            type_name = checker.context.variables[checker.current_fn][node.value].type_name
        }
    }
    if type_name == "" {
        panic("Unable to infer type: $node")
    }

    return type_name.replace("ref ", "")
}

// Utilities

fn (mut checker Checker) get_struct_field_by_name(struct_name string, field_name string) ast.FunctionArgument {
    for field in checker.context.structs[struct_name].fields {
        if field.name == field_name {
            return field
        }
    }

    // Should be unreachable
    return ast.FunctionArgument{}
}

fn (mut checker Checker) fn_has_arg_with_name(fn_name string, arg_name string) bool {
    for arg in checker.context.functions[fn_name].args {
        if arg.name == arg_name {
            return true
        }
    }

    // should be unreachable
    return false
}

fn (mut checker Checker) fn_get_arg_with_name(fn_name string, arg_name string) ast.FunctionArgument {
    for arg in checker.context.functions[fn_name].args {
        if arg.name == arg_name {
            return arg
        }
    }

    // should be unreachable
    return ast.FunctionArgument{}
}

fn (mut checker Checker) get_function_node_by_name(mod string, name string) ast.FunctionDeclarationStatement {
    if mod != "" {
        if !checker.contexts.keys().contains(mod) {
            // TODO
            panic("Trying to reference unknown module: ${mod}")
        }
        if !checker.contexts[mod].functions.keys().contains(name) {
            panic("Trying to call unknown function: `$name` in module `$mod`")
        }
        return checker.contexts[mod].functions[name]
    } else {
        // If its not a function definition
        if !checker.context.functions.keys().contains(name) {
            return checker.resolve_callchain_to_fn(name.split("."))
        } else {
            return checker.context.functions[name]
        }
    }
    // should be unreachable
    panic("checker.get_function_node_by_name: mod: $mod name: $name")
    return ast.FunctionDeclarationStatement{}
}

fn resolve_function_name(name string) (string, string) {
    mut function_name := name
    mut mod_name := ""
    if name.contains(":") {
        mod_name = name.split(":")[0]
        function_name = name.split(":")[1]
    }
    return mod_name, function_name
}

fn (mut checker Checker) get_fn_declaration_from_struct(structdecl ast.StructDeclarationStatement, name string) ast.FunctionDeclarationStatement {
    for member_fn in structdecl.member_fns {
        if member_fn.name == name {
            return member_fn
        }
    }

    panic("Unreachable: get_fn_declaration_from_struct")
}

fn (mut checker Checker) resolve_callchain_to_fn(chain []string) ast.FunctionDeclarationStatement {
    mut types_of_each := []string{}
    println(chain)
    for call in chain {
        // we are accessing a variable
        if checker.context.variables[checker.current_fn].keys().contains(call) {
            types_of_each << checker.infer(checker.context.variables[checker.current_fn][call])
        } else {
            latest_type := types_of_each[types_of_each.len - 1]
            if latest_type.contains(":") {
                // a module
                struct_def := checker.contexts[latest_type.split(":")[0]].structs[latest_type]
                return checker.get_fn_declaration_from_struct(struct_def, call)
            } else {
                panic("Unhandled: resolve_callchain_to_fn (doesnt contain :)")
            }
            panic("Unhandled: resolve_callchain_to_fn: $call")
        }
    }

    return ast.FunctionDeclarationStatement{}
}
