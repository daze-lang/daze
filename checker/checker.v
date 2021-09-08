module checker

import ast{CompilationResult, Module}
import utils

pub struct Checker {
pub:
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

pub fn (mut checker Checker) run() ast.AST {
    // when we initialize the type checker, it first goes through every imported module
    // and typechecks them in an isolated space
    for modname, mod in checker.modules {
        checker.current_mod = modname
        for mut node in mod.ast.nodes {
            checker.check(mut &node)
        }
    }

    // when we get to the main module, we set it as the current module and start the type checker
    checker.current_mod = "main"
    for mut node in checker.ast.nodes {
        checker.check(mut &node)
    }

    return checker.ast
}


pub fn (mut checker Checker) check(mut node &ast.Node) {
    match node {
        ast.Statement {
            mut cast := node as ast.Statement
            checker.statement(cast)
        }
        ast.Expr {
            mut cast := node as ast.Expr
            checker.expr(mut &cast)
        }
    }
}

fn (mut checker Checker) statement(node ast.Statement) {
    match node {
        ast.FunctionDeclarationStatement {
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

            for mut body in node.body {
                checker.check(mut body)
            }
        } ast.StructDeclarationStatement {
            // if checker.current_mod != "main" {
            //     checker.context.structs[checker.current_mod + ":" + node.name] = node
            // } else {
                checker.context.structs[node.name] = node
            // }
        } ast.EnumDeclarationStatement {
            checker.context.enums[node.name] = node
        } ast.GlobalDecl {
            if node.name != node.name.capitalize() {
                utils.error("Global variable names must be uppercase, found: `$node.name`")
            }
        } ast.ModuleDeclarationStatement {
            if node.name == node.name.capitalize() {
                utils.error("Module names must be lowercase, found: `$node.name`")
            }
            // creating new context when a new module use statement is found
            context := new_context(node.name)
            checker.contexts[checker.context.mod_name] = checker.context
            checker.context = context
        } else {
            // println("Unchecked statement: $node")
        }
    }
}


fn (mut checker Checker) expr(mut node ast.Expr) {
    // if mut node is ast.VariableDecl {
    //     checker.var_decl(mut &node)
    // }

    match mut node {
        ast.FunctionCallExpr {
            checker.fn_call(mut &node, checker.context)
        } ast.VariableDecl {
            checker.var_decl(mut &node)
        } ast.StructInitialization {
            checker.struct_init(mut &node)
        } ast.CallChainExpr {
           checker.callchain(&node)
        } ast.BinaryOperation {
            checker.binary(mut &node)
        } ast.OptionalFunctionCall {
            checker.optional(mut &node)
        } ast.VariableAssignment {
            checker.var_assignment(mut &node)
        } ast.VariableExpr {
            cast := node as ast.VariableExpr
            if !checker.context.variables[checker.current_fn].keys().contains(cast.value)
                && !checker.context.enums.keys().contains(cast.value.split(":")[0])  {
                if cast.value !in ["true", "false"] {
                    panic("Accessing unknown variable: ${cast.value}")
                }
            }

            if cast.value.contains(":") {
                // module or enum
                mod_or_enum_name := cast.value.split(":")[0]
                field := cast.value.split(":")[1]
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
        } else {
            // println("Unchecked expression: $node")
        }
    }
}

fn (mut checker Checker) var_decl(mut node &ast.VariableDecl) {
    checker.check(mut node.value)
    mut expected := node.type_name.replace("::", ":").replace("ref ", "")
    infer_ctx := TypeInferenceContext{
        expr: node.value
        context: checker.context
    }
    my_type := checker.infer(infer_ctx)
    if expected == "" {
        node.type_name = my_type
        expected = my_type
    }

    if expected != my_type {
        if my_type != "Any" {
            panic("Type mismatch. Trying to assign ${my_type} to variable `${node.name}`, but it expects ${expected}")
        }
    }

    checker.context.variables[checker.current_fn][node.name] = node
    // checking the variable body
    checker.check(mut node.value)
}

fn (mut checker Checker) fn_call(mut node ast.FunctionCallExpr, context Context) {
    mut function_name := node.name

    if function_name in ["tostring", "toint"] {
        return
    }

    if !context.functions.keys().contains(function_name) {
        panic("Trying to call undefined function `$function_name`")
    }

    fn_node := context.functions[function_name]
    // TODO: check if it exists

    for mut arg in node.args {
        checker.check(mut arg)
    }

    if function_name == "main" {
        panic("Calling `main` is not allowed.")
    }

    checker.function_call_args(fn_node, mut node)
}

fn (mut checker Checker) function_call_args(declaration ast.FunctionDeclarationStatement, mut call ast.FunctionCallExpr) {
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
        checker.check(mut call.args[i])
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

fn (mut checker Checker) struct_init(mut node ast.StructInitialization) {
    args_len := node.args.len
    ast_node := checker.context.structs[node.name]
    println(node.name)
    // Checking argument types
    for i in 0..args_len {
        checker.check(mut node.args[i])
        expected := ast_node.fields[i].type_name
        my_type := checker.infer(TypeInferenceContext{expr: node.args[i], context: checker.context})

        if expected != my_type {
            panic("Type mismatch: Trying to assign ${my_type} to ${node.name}.${ast_node.fields[i].name}, but it expects $expected")
        }
    }
}

fn (mut checker Checker) array_init(expected_type string, mut node ast.ArrayInit) {
    expected := expected_type.split("|")[0]
    // // Checking argument types
    for i in 0..node.body.len {
        my_type := checker.infer(TypeInferenceContext{expr: node.body[i], context: checker.context})
        checker.check(mut node.body[i])

        if expected != my_type {
            // TODO: proper error message
            panic("Type mismatch")
        }
    }
}

fn (mut checker Checker) binary(mut node ast.BinaryOperation) {
    checker.check(mut node.lhs)
    checker.check(mut node.rhs)

    lhs_type := checker.infer(TypeInferenceContext{expr: node.lhs, context: checker.context})
    rhs_type := checker.infer(TypeInferenceContext{expr: node.rhs, context: checker.context})

    if lhs_type != rhs_type {
        panic("Type mismatch in binary. Got: ${rhs_type}, expected: ${lhs_type}")
    }

    if node.lhs is ast.BinaryOperation {
        mut lhs_cast := node.lhs as ast.BinaryOperation
        checker.binary(mut lhs_cast)
    }

    if node.rhs is ast.BinaryOperation {
        mut rhs_cast := node.rhs as ast.BinaryOperation
        checker.binary(mut rhs_cast)
    }
}

fn (mut checker Checker) optional(mut node ast.OptionalFunctionCall) {
    checker.check(mut node.fn_call)
    type_name := checker.infer(TypeInferenceContext{expr: node.fn_call, context: checker.context}).replace("?", "")
    default_type_ctx := TypeInferenceContext{expr: node.default, context: checker.context}
    if type_name != checker.infer(default_type_ctx) {
        // TODO
        panic("Optional function call & default value types don't match.")
    }
}

fn (mut checker Checker) var_assignment(mut node ast.VariableAssignment) {
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

    checker.check(mut node.value)
    my_type := checker.infer(TypeInferenceContext{expr: node.value, context: checker.context})

    if expected != my_type {
        panic("Type mismatch. Trying to assign ${my_type} to variable `${node.name}`, but it expects ${expected}")
    }

    // checking the variable body
    checker.check(mut node.value)
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
    } else if node is ast.StructInitialization {
        type_name = node.name
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
            if node.value in ["true", "false"] {
                return "Bool"
            }
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
                    if context.variables[checker.current_fn].keys().contains(call.value) {
                        latest_type = context.variables[checker.current_fn][call.value].type_name
                    }
                    // println(context.variables[checker.current_fn])
                    // panic("Error to be decided. (checker.v:400) ($latest_type)")
                }
                latest_type = checker.infer(TypeInferenceContext{expr: call, context: context, last_known_type: latest_type})
            }
        } else if mut call is ast.FunctionCallExpr {
            if context.structs.keys().contains(latest_type) {
                checker.function_call_args(checker.get_struct_member_fn_by_name(context, latest_type, call.name), mut call)
            } else {
                if !context.functions.keys().contains(call.name) {
                    panic("Trying to call undefined function `${call.name}` in module `${context.mod_name} (latest type: $latest_type)`")
                }
                checker.fn_call(mut call, context)
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

    panic("Trying to access field `$field_name` on struct `$struct_name`, but it does not exist")
}

fn (mut checker Checker) fn_has_arg_with_name(fn_name string, arg_name string) bool {
    for arg in checker.context.functions[fn_name].args {
        if arg.name == arg_name {
            return true
        }
    }

    panic("Unreachable: checker.fn_has_arg_with_name")
    return false
}

fn (mut checker Checker) fn_get_arg_with_name(fn_name string, arg_name string) ast.FunctionArgument {
    for arg in checker.context.functions[fn_name].args {
        if arg.name == arg_name {
            return arg
        }
    }

    panic("Unreachable: checker.fn_get_arg_with_name")
    return ast.FunctionArgument{}
}