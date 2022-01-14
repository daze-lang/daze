module codegen

import ast
import parser{is_binary_op}
// import utils

pub struct ParrotCodeGenerator {
pub:
    ast ast.AST
}

pub fn new_parrot(ast ast.AST) ParrotCodeGenerator {
    return ParrotCodeGenerator{ast}
}

pub fn (mut gen ParrotCodeGenerator) run() string {
    mut code := ""

    for node in gen.ast.nodes {
       code += gen.gen(node)
    }

    return code
}

pub fn (mut gen ParrotCodeGenerator) gen(node ast.Node) string {
    mut code := ""

    if mut node is ast.Statement {
        code += gen.statement(node)
    } else if mut node is ast.Expr {
        code += gen.expr(node)
    }

    return code
}

fn (mut gen ParrotCodeGenerator) statement(node ast.Statement) string {
    mut code := ""
    match node {
        ast.FunctionDeclarationStatement {
            code = gen.fn_decl(node)
        }
        ast.FunctionArgument {
            code = gen.fn_arg(node)
        }
        ast.ModuleDeclarationStatement {
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

fn (mut gen ParrotCodeGenerator) expr(node ast.Expr) string {
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

fn (mut gen ParrotCodeGenerator) fn_decl(node ast.FunctionDeclarationStatement) string {
    return ""
}

fn (mut gen ParrotCodeGenerator) generate_array_def(info string) string {
    return ""

}

fn (mut gen ParrotCodeGenerator) generate_map_def(info string) string {
    return ""

}

fn (mut gen ParrotCodeGenerator) typename(name string) string {
    return ""
}

fn (mut gen ParrotCodeGenerator) fn_arg(node ast.FunctionArgument) string {
    return ""
}

fn (mut gen ParrotCodeGenerator) fn_call(node ast.FunctionCallExpr) string {
    return ""
}

fn (mut gen ParrotCodeGenerator) string_literal_expr(node ast.StringLiteralExpr) string {
    return ""
}

fn (mut gen ParrotCodeGenerator) number_literal_expr(node ast.NumberLiteralExpr) string {
    return ""
}

fn (mut gen ParrotCodeGenerator) variable_expr(node ast.VariableExpr) string {
    return ""
}

fn (mut gen ParrotCodeGenerator) return_expr(node ast.ReturnExpr) string {
    return ""
}

fn (mut gen ParrotCodeGenerator) variable_decl(node ast.VariableDecl) string {
    return ""
}

fn (mut gen ParrotCodeGenerator) variable_assignment(node ast.VariableAssignment) string {
    return ""
}

fn (mut gen ParrotCodeGenerator) struct_decl(node ast.StructDeclarationStatement) string {
    return ""
}

fn (mut gen ParrotCodeGenerator) set_module(name string) {
    // gen.mod = name
}

fn (mut gen ParrotCodeGenerator) if_statement(node ast.IfExpression) string {
    return ""
}

fn (mut gen ParrotCodeGenerator) for_loop(node ast.ForLoopExpr) string {
    return ""
}

fn (mut gen ParrotCodeGenerator) for_in_loop(node ast.ForInLoopExpr) string {
    return ""

}

fn (mut gen ParrotCodeGenerator) array(node ast.ArrayDefinition) string {
    return ""
}

fn (mut gen ParrotCodeGenerator) indexing(node ast.IndexingExpr) string {
    return ""
}

fn (mut gen ParrotCodeGenerator) grouped_expr(node ast.GroupedExpr) string {
    return ""
}

fn (mut gen ParrotCodeGenerator) array_init(node ast.ArrayInit) string {
    return ""
}

fn (mut gen ParrotCodeGenerator) map_init(node ast.MapInit) string {
    return ""
}

fn (mut gen ParrotCodeGenerator) struct_init(node ast.StructInitialization) string {
    return ""
}

fn (mut gen ParrotCodeGenerator) try(assign_to string, node ast.OptionalFunctionCall) string {
    return ""
}

fn (mut gen ParrotCodeGenerator) binary(node ast.BinaryOperation) string {
    return ""
}

fn (mut gen ParrotCodeGenerator) enum_(node ast.EnumDeclarationStatement) string {
    return ""
}

fn (mut gen ParrotCodeGenerator) typecast(node ast.TypeCast) string {
    return ""
}

fn (mut gen ParrotCodeGenerator) callchain(node ast.CallChainExpr) string {
    return ""
}

fn (mut gen ParrotCodeGenerator) ternary(node ast.TernaryExpr) string {
    return ""
}
