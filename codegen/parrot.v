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
    for node in gen.ast.nodes {
       gen.gen(node)
    }

    return ""
}

pub fn (mut gen ParrotCodeGenerator) gen(node ast.Node) {
    if mut node is ast.Statement {
        gen.statement(node)
    } else if mut node is ast.Expr {
        gen.expr(node)
    }
}

fn (mut gen ParrotCodeGenerator) statement(node ast.Statement) {
    match node {
        ast.FunctionDeclarationStatement {
            gen.fn_decl(node)
        }
        ast.FunctionArgument {
            gen.fn_arg(node)
        }
        ast.ModuleDeclarationStatement {
        }
        ast.RawCppCode {
            node.body
        }
        ast.StructDeclarationStatement {
            gen.struct_decl(node)
        }
        ast.EnumDeclarationStatement {
            gen.enum_(node)
        }
        ast.GlobalDecl {
        }
        ast.ModuleUseStatement {
        }
        ast.Comment {
        }
        else {}
    }
}

fn (mut gen ParrotCodeGenerator) expr(node ast.Expr) {

    match node {
        ast.StringLiteralExpr {
            gen.string_literal_expr(node)
        }
        ast.CharLiteralExpr {

        }
        ast.NumberLiteralExpr {
            gen.number_literal_expr(node)
        }
        ast.FunctionCallExpr {
            gen.fn_call(node)
        }
        ast.CallChainExpr {
            gen.callchain(node)
        }
        ast.VariableExpr {
            gen.variable_expr(node)
        }
        ast.RawCppCode {
            node.body
        }
        ast.VariableAssignment {
            gen.variable_assignment(node)
        }
        ast.BinaryOp {
        }
        ast.BinaryOperation {
            gen.binary(node)
        }
        ast.ReturnExpr {
            gen.return_expr(node)
        }
        ast.VariableDecl {
            gen.variable_decl(node)
        }
        ast.RawBinaryOpExpr {
            node.value
        }
        ast.IfExpression {
            gen.if_statement(node)
        }
        ast.ForLoopExpr {
            gen.for_loop(node)
        }
        ast.ArrayDefinition {
            gen.array(node)
        }
        ast.StructInitialization {
            gen.struct_init(node)
        }
        ast.ArrayPushExpr {
        }
        ast.IncrementExpr {
        }
        ast.DecrementExpr {
        }
        ast.ForInLoopExpr {
            gen.for_in_loop(node)
        }
        ast.IndexingExpr {
            gen.indexing(node)
        }
        ast.TernaryExpr {
            gen.ternary(node)
        }
        ast.GroupedExpr {
            gen.grouped_expr(node)
        }
        ast.ArrayInit {
            gen.array_init(node)
        }
        ast.MapInit {
            gen.map_init(node)
        }
        ast.Comment {
        }
        ast.TypeCast {
            gen.typecast(node)
        }
        else {}
    }
}

fn (mut gen ParrotCodeGenerator) fn_decl(node ast.FunctionDeclarationStatement) {
}

fn (mut gen ParrotCodeGenerator) generate_array_def(info string) {

}

fn (mut gen ParrotCodeGenerator) generate_map_def(info string) {

}

fn (mut gen ParrotCodeGenerator) typename(name string) {
}

fn (mut gen ParrotCodeGenerator) fn_arg(node ast.FunctionArgument) {
}

fn (mut gen ParrotCodeGenerator) fn_call(node ast.FunctionCallExpr) {
}

fn (mut gen ParrotCodeGenerator) string_literal_expr(node ast.StringLiteralExpr) {
}

fn (mut gen ParrotCodeGenerator) number_literal_expr(node ast.NumberLiteralExpr) {
}

fn (mut gen ParrotCodeGenerator) variable_expr(node ast.VariableExpr) {
}

fn (mut gen ParrotCodeGenerator) return_expr(node ast.ReturnExpr) {
}

fn (mut gen ParrotCodeGenerator) variable_decl(node ast.VariableDecl) {
}

fn (mut gen ParrotCodeGenerator) variable_assignment(node ast.VariableAssignment) {
}

fn (mut gen ParrotCodeGenerator) struct_decl(node ast.StructDeclarationStatement) {
}

fn (mut gen ParrotCodeGenerator) set_module(name string) {
    // gen.mod = name
}

fn (mut gen ParrotCodeGenerator) if_statement(node ast.IfExpression) {
}

fn (mut gen ParrotCodeGenerator) for_loop(node ast.ForLoopExpr) {
}

fn (mut gen ParrotCodeGenerator) for_in_loop(node ast.ForInLoopExpr) {

}

fn (mut gen ParrotCodeGenerator) array(node ast.ArrayDefinition) {
}

fn (mut gen ParrotCodeGenerator) indexing(node ast.IndexingExpr) {
}

fn (mut gen ParrotCodeGenerator) grouped_expr(node ast.GroupedExpr) {
}

fn (mut gen ParrotCodeGenerator) array_init(node ast.ArrayInit) {
}

fn (mut gen ParrotCodeGenerator) map_init(node ast.MapInit) {
}

fn (mut gen ParrotCodeGenerator) struct_init(node ast.StructInitialization) {
}

fn (mut gen ParrotCodeGenerator) try(assign_to string, node ast.OptionalFunctionCall) {
}

fn (mut gen ParrotCodeGenerator) binary(node ast.BinaryOperation) {
}

fn (mut gen ParrotCodeGenerator) enum_(node ast.EnumDeclarationStatement) {
}

fn (mut gen ParrotCodeGenerator) typecast(node ast.TypeCast) {
}

fn (mut gen ParrotCodeGenerator) callchain(node ast.CallChainExpr) {
}

fn (mut gen ParrotCodeGenerator) ternary(node ast.TernaryExpr) {
}
