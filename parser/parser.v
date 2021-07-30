module parser

import lexer{Token}
import ast{AST, Statement, Expr, Node}

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

fn (mut parser Parser) statements() []Statement {
    mut statements := []Statement{}
    for parser.lookahead().kind != .eof {
        statements << parser.statement()
    }
    return statements
}

fn (mut parser Parser) statement() Statement {
    mut node := ast.Statement{}
    match parser.lookahead().kind {
        .kw_fn {
            node = parser.fn_decl()
        }
        .kw_is {
            if parser.lookahead_by(2).kind == .identifier {
                node = parser.module_decl()
            }
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
fn (mut parser Parser) fn_decl() Statement {
    parser.expect(.kw_fn)
    fn_name := parser.expect(.identifier).value
    parser.expect(.open_paren)
    mut args := []ast.FunctionArgument{}
    if parser.lookahead().kind == .identifier {
        args = parser.fn_args()
    }
    parser.expect(.close_paren)
    parser.expect(.double_colon)

    ret_type := parser.expect(.identifier).value
    parser.expect(.open_curly)

    mut body := []Expr{}
    for parser.lookahead().kind != .close_curly {
        body << parser.expr()
    }
    parser.expect(.close_curly)

    return ast.FunctionDeclarationStatement{
        name: fn_name,
        args: args,
        body: body,
        return_type: ret_type
    }
}

fn (mut parser Parser) fn_args() []ast.FunctionArgument {
    mut args := []ast.FunctionArgument{}

    for parser.lookahead().kind != .close_paren {
        args << parser.fn_arg()
        if parser.lookahead().kind != .close_paren {
            parser.expect(.comma)
        }
    }

    return args
}

fn (mut parser Parser) fn_arg() ast.FunctionArgument {
    name := parser.expect(.identifier).value
    parser.expect(.double_colon)
    type_name := parser.expect(.identifier).value

    return ast.FunctionArgument {
        name: name,
        type_name: type_name
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

fn (mut parser Parser) module_decl() Statement {
    parser.expect(.kw_is)
    module_name := parser.advance().value
    node := ast.ModuleDeclarationStatement{
        name: module_name
    }
    parser.expect(.semicolon)
    return node
}