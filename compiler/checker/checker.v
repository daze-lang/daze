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

struct TypeInferenceContext {
    expr ast.Expr
    context Context
    last_known_type string
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
            panic("Fn already defined. (${node.name})")
        }
        checker.context.functions[node.name] = node

        // pushing arguments as variables for a function declaration
        for arg in node.args {
            arg_as_var := ast.VariableDecl{
                name: arg.name
                value: ast.NoOp{}
                type_name: arg.type_name
            }
            checker.context.variables[checker.current_fn][arg.name] = arg_as_var
        }

        for body in node.body {
            checker.check(body)
        }
    } else if node is ast.StructDeclarationStatement {
        // if checker.current_mod != "main" {
        //     checker.context.structs[checker.current_mod + ":" + node.name] = node
        // } else {
            checker.context.structs[node.name] = node
        // }
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
        checker.fn_call(node, checker.context)
    } else if node is ast.VariableDecl {
        checker.var_decl(node)
    } else if node is ast.StructInitialization {
        checker.struct_decl(node)
    } else if node is ast.CallChainExpr {
       checker.callchain(node)
    } else if node is ast.BinaryOperation {
        checker.binary(node)
    } else if node is ast.OptionalFunctionCall {
        checker.optional(node)
    } else if node is ast.VariableAssignment {
        checker.var_assignment(node)
    } else if node is ast.VariableExpr {
        if !checker.context.variables[checker.current_fn].keys().contains(node.value)
            && !checker.context.enums.keys().contains(node.value.split(":")[0])  {
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
    infer_ctx := TypeInferenceContext{
        expr: node.value
        context: checker.context
    }
    my_type := checker.infer(infer_ctx)

    if expected != my_type {
        if my_type != "Any" {
            panic("Type mismatch. Trying to assign ${my_type} to variable `${node.name}`, but it expects ${expected}")
        }
    }

    checker.context.variables[checker.current_fn][node.name] = node

    // checking the variable body
    checker.check(node.value)
}

fn (mut checker Checker) fn_call(node ast.FunctionCallExpr, context Context) {
    mut function_name := node.name

    if function_name in ["tostring", "toint"] {
        return
    }

    if !context.functions.keys().contains(function_name) {
        panic("Trying to call undefined function `$function_name`")
    }

    fn_node := context.functions[function_name]
    // TODO: check if it exists

    for arg in node.args {
        checker.check(arg)
    }

    if function_name == "main" {
        panic("Calling `main` is not allowed.")
    }

    checker.function_call_args(fn_node, node)
}

fn (mut checker Checker) function_call_args(declaration ast.FunctionDeclarationStatement, call ast.FunctionCallExpr) {
    mut function_name := call.name

    // Checking argument count
    args_len := declaration.args.len
    if call.args.len > args_len {
        panic("Too many arguments to call $function_name; got ${call.args.len}, expected ${args_len}")
    }

    if call.args.len < args_len {
        panic("Too few arguments to call $function_name; got ${call.args.len}, expected ${args_len}")
    }

    // Checking argument types
    for i in 0..args_len {
        checker.check(call.args[i])
        expected := declaration.args[i].type_name.replace("ref ", "")
        my_type := checker.infer(TypeInferenceContext{expr: call.args[i], context: checker.context})

        if expected == "Any" {
            return
        }

        if expected != my_type {
            panic("Type mismatch. Trying to call function `$function_name` with argument `${declaration.args[i].name}` as ${my_type}, but it expects ${expected}")
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
        my_type := checker.infer(TypeInferenceContext{expr: node.args[i], context: checker.context})

        if expected != my_type {
            panic("Type mismatch: Trying to assign ${my_type} to ${node.name}.${ast_node.fields[i].name}, but it expects $expected")
        }
    }
}

fn (mut checker Checker) array_init(expected_type string, node ast.ArrayInit) {
    expected := expected_type.split("|")[0]
    // // Checking argument types
    for i in 0..node.body.len {
        my_type := checker.infer(TypeInferenceContext{expr: node.body[i], context: checker.context})
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

    lhs_type := checker.infer(TypeInferenceContext{expr: node.lhs, context: checker.context})
    rhs_type := checker.infer(TypeInferenceContext{expr: node.rhs, context: checker.context})

    if lhs_type != rhs_type {
        panic("Type mismatch in binary. Got: ${rhs_type}, expected: ${lhs_type}")
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
    type_name := checker.infer(TypeInferenceContext{expr: node.fn_call, context: checker.context}).replace("?", "")
    default_type_ctx := TypeInferenceContext{expr: node.default, context: checker.context}
    if type_name != checker.infer(default_type_ctx) {
        // TODO
        panic("Optional function call & default value types don't match.")
    }
}

fn (mut checker Checker) var_assignment(node ast.VariableAssignment) {
    mut expected := "UNKNOWN"
    if !checker.context.variables[checker.current_fn].keys().contains(node.name) {
        if checker.fn_has_arg_with_name(checker.current_fn, node.name) {
            expected = checker.fn_get_arg_with_name(checker.current_fn, node.name).type_name.replace("ref ", "")
        } else {
            panic("Trying to assign to unknown variable `$node.name` in function `$checker.current_fn`")
        }

    } else {
        expected = checker.infer(TypeInferenceContext{
            expr: checker.context.variables[checker.current_fn][node.name].value,
            context: checker.context
        })
    }

    checker.check(node.value)
    my_type := checker.infer(TypeInferenceContext{expr: node.value, context: checker.context})

    if expected != my_type {
        panic("Type mismatch. Trying to assign ${my_type} to variable `${node.name}`, but it expects ${expected}")
    }

    // checking the variable body
    checker.check(node.value)
}

// Type Inference

fn (mut checker Checker) infer(inference_context TypeInferenceContext) string {
    node := inference_context.expr
    context := inference_context.context
    last_type := inference_context.last_known_type

    mut type_name := ""

    if node is ast.IndexingExpr {
        type_name = checker.infer(TypeInferenceContext{expr: ast.VariableExpr{node.var, false, false}, context: context})
        if !type_name.contains("|") {
            panic("Indexing is only allowed for array types")
        }

        type_name = type_name.split("|")[0]
    } else if node is ast.BinaryOperation {
        type_name = checker.infer(TypeInferenceContext{expr: node.lhs, context: context})
    } else if node is ast.CallChainExpr {
        return checker.callchain(node)
    } else if node is ast.OptionalFunctionCall {
        type_name = checker.infer(TypeInferenceContext{expr: node.fn_call, context: context})
    } else if node is ast.MapInit {
        key_type := checker.infer(TypeInferenceContext{expr: node.body[0].key, context: context})
        value_type := checker.infer(TypeInferenceContext{expr: node.body[0].value, context: context})
        type_name = "$key_type->$value_type"
    } else if node is ast.FunctionCallExpr {
        type_name = context.functions[node.name].return_type.replace("?", "")
        if type_name == "" {
            if !context.structs.keys().contains(last_type) {
                panic("Trying to call function on nonexistent struct ($last_type)")
            }

            return checker.get_struct_member_fn_by_name(context, context.structs[last_type].name, node.name).return_type
        }
    } else if node is ast.StringLiteralExpr {
        type_name = "String"
    } else if node is ast.NumberLiteralExpr {
        type_name = "Int"
    } else if node is ast.StructInitialization {
        type_name = node.name
    } else if node is ast.ArrayInit {
        // TODO:
        type_name = "Any"
    } else if node is ast.TypeCast {
        type_name = node.type_name
    } else if node is ast.RawCppCode {
        type_name = "Any"
    } else if node is ast.VariableDecl {
        type_name = node.type_name.replace("::", ":")
    } else if node is ast.VariableExpr {
        if context.variables[checker.current_fn][node.value].type_name == "" {
            enum_name := node.value.split(":")[0]
            if context.enums.keys().contains(enum_name) {
                type_name = enum_name
            }
        }
        type_name = context.variables[checker.current_fn][node.value].type_name

        // possibly struct field access
        if type_name == "" {
            // TODO: check if struct exists
            return checker.get_struct_field_by_name(context, last_type, node.value).type_name
        }
    }

    if type_name == "" {
        panic("Unable to infer type: $node")
    }

    return type_name.replace("ref ", "")
}

fn (mut checker Checker) callchain(node ast.CallChainExpr) string {
    mut context := checker.context
    mut latest_type := ""
    for call in node.chain {
        if call is ast.VariableExpr {
            // Trying to call on module
            if call.mod {
                // check if module exists
                if !checker.contexts.keys().contains(call.value) {
                    panic("Trying to reference undefined module `${call.value}`")
                }

                context = checker.contexts[call.value]
            } else {
                if !context.structs.keys().contains(latest_type) {
                    panic("Error to be decided. (checker.v:400)")
                }
                latest_type = checker.infer(TypeInferenceContext{expr: call, context: context, last_known_type: latest_type})
            }
        } else if call is ast.FunctionCallExpr {
            if context.structs.keys().contains(latest_type) {
                checker.function_call_args(checker.get_struct_member_fn_by_name(context, latest_type, call.name), call)
            } else {
                if !context.functions.keys().contains(call.name) {
                    panic("Trying to call undefined function `${call.name}` in module `${context.mod_name} (latest type: $latest_type)`")
                }
                checker.fn_call(call, context)
            }
            latest_type = checker.infer(TypeInferenceContext{expr: call, context: context, last_known_type: latest_type})
        }
    }

    return latest_type
}

// Utilities

fn (mut checker Checker) get_struct_member_fn_by_name(
    context Context,
    struct_name string,
    fn_name string) ast.FunctionDeclarationStatement {
    for member_fn in context.structs[struct_name].member_fns {
        if member_fn.name == fn_name {
            return member_fn
        }
    }

    // Should be unreachable
    panic("Trying to call function `$fn_name` on struct `$struct_name`, but it does not exist")
}

fn (mut checker Checker) get_struct_field_by_name(
    context Context,
    struct_name string,
    field_name string) ast.FunctionArgument {
    for field in context.structs[struct_name].fields {
        if field.name == field_name {
            return field
        }
    }

    // Should be unreachable
    panic("Trying to access field `$field_name` on struct `$struct_name`, but it does not exist")
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