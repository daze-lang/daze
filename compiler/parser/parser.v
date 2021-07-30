module parser

import strconv

import lexer{Token}
import ast{AST, Statement, Expr, Node}

pub struct Parser {
    tokens []Token [required]

    mut:
        index int = -1
        current Token
        previous Token
        structs map[string]ast.StructDeclarationStatement = map[string]ast.StructDeclarationStatement{}
}

pub fn (mut parser Parser) parse() AST {
    mut statements := parser.statements()
    for _, v in parser.structs {
        statements << v
    }
    // a << statements
    ast := AST{"TopLevel", statements}
    // panic(ast)
    return ast
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
        .kw_implement {
            parser.implement_block()
        }
        .raw_crystal_code {
            node = parser.raw_crystal_code()
        }
        .kw_use {
            node = parser.use()
        }
        .kw_struct {
            construct := parser.construct()
            parser.structs[construct.name] = construct
        }
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
        .number {
            node = ast.NumberLiteralExpr{strconv.atoi(parser.lookahead().value) or { 0 }}
            parser.advance()
        }
        .kw_return {
            node = parser.ret()
        }
        .identifier {
            match parser.lookahead_by(2).kind {
                .open_paren {
                    node = parser.fn_call()
                }
                else {
                    if parser.lookahead_by(2).kind == .equal {
                        node = parser.variable_decl()
                    } else {
                        node = ast.VariableExpr{parser.lookahead().value}
                        parser.advance()
                    }
                }
            }
        }
        else {
            node = ast.NoOp{}
        }
    }

    mut raw_op := []string{}
    raw_op << parser.peek().value
    if parser.lookahead_by(1).kind == .plus
        || parser.lookahead_by(1).kind == .minus
        || parser.lookahead_by(1).kind == .mod
        || parser.lookahead_by(1).kind == .div
        || parser.lookahead_by(1).kind == .and_and
        || parser.lookahead_by(1).kind == .not
        || parser.lookahead_by(1).kind == .not_equal
        || parser.lookahead_by(1).kind == .equal_equal {

        for parser.lookahead().kind != .semicolon {
            val := parser.advance().value
            if val == "," {
                parser.step_back()
                break
            }

            if val == ")" {
                if parser.lookahead_by(-1).value == ")" {
                    parser.step_back()
                    break
                }
            }

            raw_op << val
        }

        if raw_op[0] == "=" {
            raw_op[0] = ""
        }

        return ast.RawBinaryOpExpr{raw_op.join("").replace("Self.", "@@")}
    }

    return node
}

// Function Declarations
fn (mut parser Parser) fn_decl() ast.FunctionDeclarationStatement {
    parser.expect(.kw_fn)
    fn_name := parser.expect(.identifier).value
    parser.expect(.open_paren)
    mut args := []ast.FunctionArgument{}
    if parser.lookahead().kind == .identifier {
        args = parser.fn_args(.close_paren)
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
        return_type: ret_type,
        is_struct: false
    }
}

fn (mut parser Parser) fn_args(delim lexer.TokenType) []ast.FunctionArgument {
    mut args := []ast.FunctionArgument{}

    for parser.lookahead().kind != delim {
        args << parser.fn_arg()
        if parser.lookahead().kind != delim {
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

fn (mut parser Parser) implement_block() {
    parser.expect(.kw_implement)
    name := parser.expect(.identifier).value
    parser.expect(.open_curly)

    mut fns := []ast.FunctionDeclarationStatement{}
    for parser.lookahead().kind != .close_curly {
        fns << parser.fn_decl()
    }

    for mut func in fns {
        if func.name == "new" {
            func.name = "initialize"
            func.body << ast.ReturnExpr{
                value: ast.VariableExpr{"self"},
            }
        }
        func.is_struct = true
    }


    for field in parser.structs[name].fields {
        mut body := []ast.Expr{}
        body << ast.ReturnExpr{ast.VariableExpr{"@@$field.name"}}
        func := ast.FunctionDeclarationStatement{
            name: field.name,
            args: []ast.FunctionArgument{},
            body: body,
            return_type: field.type_name,
            is_struct: true
        }
        fns << func
    }

    parser.expect(.close_curly)
    parser.structs[name].fns = fns
}

fn (mut parser Parser) fn_call() Expr {
    fn_name := parser.expect(.identifier).value
    parser.expect(.open_paren)
    mut args := []Expr{}
    for parser.lookahead().kind != .close_paren {
        args << parser.expr()
        if parser.lookahead().kind != .close_paren {
            parser.expect(.comma)
        }
    }

    parser.expect(.close_paren)
    if parser.lookahead().kind != .close_paren {
        parser.expect(.semicolon)
    }

   return ast.FunctionCallExpr{
        name: fn_name,
        args: args
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

fn (mut parser Parser) raw_crystal_code() ast.RawCrystalCodeStatement {
    return ast.RawCrystalCodeStatement{parser.advance().value}
}

fn (mut parser Parser) construct() ast.StructDeclarationStatement {
    parser.expect(.kw_struct)
    struct_name := parser.expect(.identifier).value
    parser.expect(.open_curly)
    fields := parser.fn_args(.close_curly)
    parser.expect(.close_curly)

    return ast.StructDeclarationStatement{
        name: struct_name,
        fields: fields,
        fns: []ast.FunctionDeclarationStatement{},
    }
}

fn (mut parser Parser) use() Statement {
    parser.expect(.kw_use)
    path := parser.expect(.string).value
    parser.expect(.semicolon)

    return ast.ModuleUseStatement{
        path: path
    }
}

fn (mut parser Parser) ret() Expr {
    parser.expect(.kw_return)
    value := parser.expr()
    if !(value is ast.FunctionCallExpr) {
        parser.expect(.semicolon)
    }

    return ast.ReturnExpr{
        value: value,
    }
}

fn (mut parser Parser) variable_decl() Expr {
    name := parser.expect(.identifier).value

    parser.expect(.equal)
    value := parser.expr()
    if !(value is ast.FunctionCallExpr) {
        parser.expect(.semicolon)
    }

    return ast.VariableDecl {
        name: name,
        value: value
    }
}