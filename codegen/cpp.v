module codegen

import ast
import parser{is_binary_op}
import utils

pub struct CppCodeGenerator {
pub:
    ast ast.AST
pub mut:
    vars map[string]string
    fns map[string]string
    mod_name string
}

pub fn new_cpp(ast ast.AST) CppCodeGenerator {
    return CppCodeGenerator{ast, map[string]string{}, map[string]string{}, ""}
}

pub fn (mut gen CppCodeGenerator) run() string {
    mut code := ""

    for node in gen.ast.nodes {
       code += gen.gen(node)
    }

    return code + if gen.mod_name != "main" { "\n}" } else { "" }
}

pub fn (mut gen CppCodeGenerator) gen(node ast.Node) string {
    mut code := ""

    if mut node is ast.Statement {
        code += gen.statement(node)
    } else if mut node is ast.Expr {
        code += gen.expr(node)
    }

    return code
}

fn (mut gen CppCodeGenerator) statement(node ast.Statement) string {
    mut code := ""
    match node {
        ast.FunctionDeclarationStatement {
            code = gen.fn_decl(node)
        }
        ast.FunctionArgument {
            code = gen.fn_arg(node)
        }
        ast.ModuleDeclarationStatement {
            gen.mod_name = node.name
            if node.name != "main" {
                code = "\nnamespace $node.name {\n"
            }
        }
        ast.RawCppCode {
            code = node.body
        }
        ast.StructDeclarationStatement {
            code = gen.struct_decl(node)
        }
        ast.EnumDeclarationStatement {
            code = gen.enum_(node)
        }
        ast.GlobalDecl {
            code = "const auto ${node.name} = ${gen.expr(node.value)};\n"
        }
        ast.ModuleUseStatement {
            parts := node.path.split("::")
            code = "// MODULE ${parts.pop().replace("daze::", "").replace("./", "")};\n"
        }
        ast.Comment {
            code = "// $node.value\n"
        }
        else {}
    }

    return code
}

fn (mut gen CppCodeGenerator) expr(node ast.Expr) string {
    mut code := ""

    match node {
        ast.StringLiteralExpr {
            code = gen.string_literal_expr(node)
        }
        ast.CharLiteralExpr {
            code = "'$node.value'"
        }
        ast.NumberLiteralExpr {
            code = gen.number_literal_expr(node)
        }
        ast.FunctionCallExpr {
            code = gen.fn_call(node)
        }
        ast.CallChainExpr {
            code = gen.callchain(node)
        }
        ast.VariableExpr {
            code = gen.variable_expr(node)
        }
        ast.RawCppCode {
            code = node.body
        }
        ast.VariableAssignment {
            code = gen.variable_assignment(node)
        }
        ast.BinaryOp {
            code = "$node.value"
        }
        ast.BinaryOperation {
            code = gen.binary(node)
        }
        ast.ReturnExpr {
            code = gen.return_expr(node)
        }
        ast.VariableDecl {
            code = gen.variable_decl(node)
        }
        ast.RawBinaryOpExpr {
            code = node.value
        }
        ast.IfExpression {
            code = gen.if_statement(node)
        }
        ast.ForLoopExpr {
            code = gen.for_loop(node)
        }
        ast.ArrayDefinition {
            code = gen.array(node)
        }
        ast.StructInitialization {
            code = gen.struct_init(node)
        }
        ast.ArrayPushExpr {
            code = "${node.target}.push_back(${gen.gen(node.value).replace(";", "")});\n"
        }
        ast.IncrementExpr {
            code = "$node.target++;\n"
        }
        ast.DecrementExpr {
            code = "$node.target--;\n"
        }
        ast.ForInLoopExpr {
            code = gen.for_in_loop(node)
        }
        ast.IndexingExpr {
            code = gen.indexing(node)
        }
        ast.TernaryExpr {
            code = gen.ternary(node)
        }
        ast.GroupedExpr {
            code = gen.grouped_expr(node)
        }
        ast.ArrayInit {
            code = gen.array_init(node)
        }
        ast.MapInit {
            code = gen.map_init(node)
        }
        ast.Comment {
            code = "// $node.value\n"
        }
        ast.TypeCast {
            code = gen.typecast(node)
        }
        else {}
    }

    return code
}

fn (mut gen CppCodeGenerator) fn_decl(node ast.FunctionDeclarationStatement) string {
    if node.external {
        return ""
    }

    mut args := []string{}
    for arg in node.args {
        args << gen.fn_arg(arg)
    }

    mut code := ""
    is_optional := node.return_type.ends_with("?")
    mut ret_type := node.return_type.replace("?", "")

    if node.name == "main" {
        ret_type = "Int"
    }

    code += "${gen.typename(ret_type)} ${node.name}(${args.join(", ")}) {\n"
    for expr in node.body {
        code += gen.gen(expr)
    }

    gen.fns[node.name] = if is_optional { gen.typename(ret_type) + "?" } else { gen.typename(ret_type) }
    code += "\n}\n\n"
    return code
}

fn (mut gen CppCodeGenerator) generate_array_def(info string) string {
    mut type_name := ""
    parts := info.split("|")
    level := parts[1].int()
    translated_type_name := gen.typename(parts[0])

    if level == 1 {
        return "std::vector<${translated_type_name}>"
    }

    for _ in 0..level - 1 {
        type_name += "std::vector<"
    }
    type_name += "std::vector<${translated_type_name}"
    for _ in 0..level {
        type_name += ">"
    }

    return type_name
}

fn (mut gen CppCodeGenerator) generate_map_def(info string) string {
    parts := info.split("->")
    if parts[0].contains("|") {
        // TODO
        panic("Keys cant be arrays")
    }
    mut key_type := gen.typename(parts[0])
    mut value_type := gen.typename(parts[1])

    if parts[1].contains("|") {
        value_type = gen.generate_array_def(parts[1])
    }

    return "std::map<${key_type}, ${value_type}>"
}

fn (mut gen CppCodeGenerator) typename(name string) string {
    if name.starts_with("ref ") {
        return gen.typename(name.replace("ref ", "")) + "&"
    }

    return match name {
        "String" { "std::string" }
        "Int" { "int" }
        "BigInt" { "uint64_t" }
        "Bool" { "bool" }
        "Float" { "float" }
        "Any" { "auto" }
        "Void" { "void" }
        "Char" { "char" }
        // C types
        "CString" { "char*" }
        else {
            if name.contains("|") && !name.contains("->") {
                gen.generate_array_def(name)
            } else if name.contains("->") {
                gen.generate_map_def(name)
            } else if name.count(":") == 1 {
                name.replace(":", "::")
            } else {
                // println("Unhandled type: $name")
                name
            }
        }
    }
}

fn (mut gen CppCodeGenerator) fn_arg(node ast.FunctionArgument) string {
    return "${gen.typename(node.type_name)} $node.name"
}

fn (mut gen CppCodeGenerator) fn_call(node ast.FunctionCallExpr) string {
    mut args := []string{}
    for arg in node.args {
        args << gen.expr(arg).replace(";", "")
    }

    mut fn_name := node.name.replace(":", "::")
    return "${fn_name.replace("C.", "")}(${args.join(", ")});\n".replace("; ;", "")
}

fn (mut gen CppCodeGenerator) string_literal_expr(node ast.StringLiteralExpr) string {
    if node.value.contains("{") && node.value.contains("}") {
        return "std::string(\"$node.value\")".replace("{", "\"+__tostring(").replace("}", ")+\"")
    }
    return "std::string(\"$node.value\")"
}

fn (mut gen CppCodeGenerator) number_literal_expr(node ast.NumberLiteralExpr) string {
    return "$node.value"
}

fn (mut gen CppCodeGenerator) variable_expr(node ast.VariableExpr) string {
    if node.value.contains(":") {
        return node.value.replace(":", "::")
    }
    return node.value
}

fn (mut gen CppCodeGenerator) return_expr(node ast.ReturnExpr) string {
    return "\nreturn ${gen.gen(node.value).replace("\n", " ").replace(";", "")};\n"
}

fn (mut gen CppCodeGenerator) variable_decl(node ast.VariableDecl) string {
    mut body := gen.gen(node.value)
    mut type_name := node.type_name

    mut is_optional := false
    mut optional := ast.OptionalFunctionCall{}
    cast := node.value
    if cast is ast.StructInitialization {
        type_name = cast.name.replace(":", "::")
    } else if cast is ast.OptionalFunctionCall {
        is_optional = true
        optional = cast
    } else if cast is ast.StringLiteralExpr {
        type_name = "std::string"
    } else if cast is ast.NumberLiteralExpr {
        type_name = "int"
    } else if cast is ast.CharLiteralExpr {
        type_name = "char"
    }

    gen.vars[node.name] = gen.typename(type_name)
    if is_optional {
        return "${gen.typename(type_name)} $node.name;\n${gen.try(node.name, optional)}"
    }

    return "${gen.typename(type_name)} $node.name = $body;\n"
}

fn (mut gen CppCodeGenerator) variable_assignment(node ast.VariableAssignment) string {
    return "$node.name = ${gen.gen(node.value)};\n"
}

fn (mut gen CppCodeGenerator) struct_decl(node ast.StructDeclarationStatement) string {
    mut code := "struct $node.name {\n"
    for field in node.fields {
        code += gen.fn_arg(field) + ";"
    }

    for member_fn in node.member_fns {
        code += "\n" + gen.statement(member_fn)
    }

    code += "\n};\n\n"
    return code
}

fn (mut gen CppCodeGenerator) set_module(name string) {
    // gen.mod = name
}

fn (mut gen CppCodeGenerator) if_statement(node ast.IfExpression) string {

    mut code := "if (${gen.expr(node.conditional).replace(";", "")}) {\n"
    for func in node.body {
        code += gen.gen(func)
    }

    if node.elseifs.len != 0 {
        for elsif in node.elseifs {
            code += "} else if(${gen.expr(elsif.conditional).replace(";", "")}){\n"
            for func in elsif.body {
                code += gen.gen(func)
            }
        }
    }

    if node.else_branch.len != 0 {
        code += "} else {\n"
        for func in node.else_branch {
            code += gen.gen(func)
        }
    }

    code += "}\n"
    return code
}

fn (mut gen CppCodeGenerator) for_loop(node ast.ForLoopExpr) string {
    mut conditional := "${gen.gen(node.conditional)}"
    mut code := "\nwhile (${conditional.replace(";", "")}) {\n"
    for func in node.body {
        code += gen.gen(func) + "\n"
    }
    code += "}\n"
    return code
}

fn (mut gen CppCodeGenerator) for_in_loop(node ast.ForInLoopExpr) string {
    mut code := "for (auto $node.container : ${gen.gen(node.target).replace(";", "")}) {\n"
    for expr in node.body {
        code += gen.gen(expr)
    }
    code += "\n}\n"
    return code
}

fn (mut gen CppCodeGenerator) array(node ast.ArrayDefinition) string {
    mut code := "["
    mut items := []string{}

    for item in node.items {
        items << gen.gen(item)
    }

    code += "${items.join(", ")}] of $node.type_name"
    return code
}

fn (mut gen CppCodeGenerator) indexing(node ast.IndexingExpr) string {
    return "${node.var.replace("Self.", "@")}[${gen.gen(node.body)}]"
}

fn (mut gen CppCodeGenerator) grouped_expr(node ast.GroupedExpr) string {
    return "(${gen.gen(node.body)})"
}

fn (mut gen CppCodeGenerator) array_init(node ast.ArrayInit) string {
    mut items := []string{}

    for item in node.body {
        items << gen.gen(item)
    }
    return "{${items.join(", ").replace(", ,", ",").replace(";", "")}}"
}

fn (mut gen CppCodeGenerator) map_init(node ast.MapInit) string {
    mut items := []string{}

    for item in node.body {
        items << "{${gen.gen(item.key)}, ${gen.gen(item.value)}},"
    }

    return "{${items.join("\n")}}"
}

fn (mut gen CppCodeGenerator) struct_init(node ast.StructInitialization) string {
    mut args := []string{}

    for arg in node.args {
        args << gen.expr(arg)
    }

    return "(${node.name.replace(':', '::')}){${args.join(", ").replace(",,", "").replace(", ,", ", ").replace(";", "")}}"
}

fn (mut gen CppCodeGenerator) try(assign_to string, node ast.OptionalFunctionCall) string {
    if node.fn_call is ast.FunctionCallExpr {
        if !gen.fns[node.fn_call.name].ends_with("?") {
            // TODO: proper error message
            utils.codegen_error("Trying to wrap non-optional call into a try block.")
        }
    }
    mut code := "try {\n"
    code += "$assign_to = ${gen.expr(node.fn_call)};"
    code += "\n} catch (std::string e) {\n"
    code += "$assign_to = ${gen.expr(node.default)};"
    code += "\n}\n"

    return code
}

fn (mut gen CppCodeGenerator) binary(node ast.BinaryOperation) string {
    if gen.expr(node.rhs) == "" {
        // TODO: proper error message
        panic("Couldn't parse binary op. Missing right hand side?")
    }
    return "${gen.expr(node.lhs)} ${node.op} ${gen.expr(node.rhs)}"
}

fn (mut gen CppCodeGenerator) enum_(node ast.EnumDeclarationStatement) string {
    return "enum $node.name {${node.values.join(", ")}};"
}

fn (mut gen CppCodeGenerator) typecast(node ast.TypeCast) string {
    type_name := gen.typename(node.type_name)
    if node.type_name == "CString" {
        return "tocstring(${gen.expr(node.value)})"
    } else if node.type_name == "String" {
        return "__tostring(${gen.expr(node.value)})"
    }
    return "(${type_name}) ${gen.expr(node.value)}"
}

fn (mut gen CppCodeGenerator) callchain(node ast.CallChainExpr) string {
    mut code := ""

    for c in node.chain {
        call := "${gen.expr(c).replace(";", "")}".trim_space()
        if mut c is ast.VariableExpr {
            if c.mod {
                code += "$call::"
            } else {
                code += "${call}."
            }
        } else {
            code += "${call}."
        }
    }

    return code.trim_right(".").trim_space() + ";"
}

fn (mut gen CppCodeGenerator) ternary(node ast.TernaryExpr) string {
    truthy := gen.expr(node.truthy).replace(";", "").trim_space()
    falsey := gen.expr(node.falsey).replace(";", "").trim_space()
    return "(${gen.expr(node.conditional)}) ? $truthy : $falsey;"
}
