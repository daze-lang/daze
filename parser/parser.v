module parser

import lexer{Token}
import ast{AST, Node, Expr}

pub struct Parser {
    tokens []Token [required]

    mut:
        index int = -1
        current Token
        previous Token
}

pub fn (mut parser Parser) parse() AST {
    return AST{"TopLevel", parser.statements()}
}

fn (mut parser Parser) statements() []Node {
    mut statements := []Node{}
    for parser.lookahead().kind != .eof {
        statements << parser.statement()
    }
    return statements
}

fn (mut parser Parser) statement() Node {
    mut node := ast.Node{}
    match parser.lookahead().kind {
        .kw_fn {
            node = parser.fn_decl()
        }
        else {}
    }

    return node
}

fn (mut parser Parser) expr() Expr {
    mut node := ast.Expr{}
    match parser.lookahead().kind {
        .string {
            node = ast.StringLiteralExpr{parser.lookahead().value}
            parser.advance()
        }
        .identifier {
            match parser.lookahead_by(2).kind {
                .open_paren {
                    node = parser.fn_call()
                }
                else {}
            }
        }
        else {
            node = ast.NoOp{}
        }
    }

    return node
}

// Function Declarations
fn (mut parser Parser) fn_decl() Node {
    parser.expect(.kw_fn)
    fn_name := parser.expect(.identifier).value
    parser.expect(.open_paren)
    parser.expect(.close_paren)
    parser.expect(.double_colon)

    ret_type := parser.expect(.identifier).value
    parser.expect(.open_curly)
    expr := parser.expr()
    parser.expect(.close_curly)

    return ast.FunctionDeclarationStatement{
        name: fn_name,
        body: expr,
        return_type: ret_type
    }
}

fn (mut parser Parser) fn_call() Expr {
    fn_name := parser.expect(.identifier).value
    parser.expect(.open_paren)
    arg := parser.expr()
    parser.expect(.close_paren)
    parser.expect(.semicolon)

   return ast.FunctionCallExpr{
        name: fn_name,
        args: arg
   }
}