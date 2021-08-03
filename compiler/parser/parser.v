module parser

import strconv

import lexer{Token, is_keyword}
import ast{AST, Statement, Expr, Node}
import utils

pub struct Parser {
    tokens []Token [required]

    mut:
        index int = -1
        current Token
        previous Token
        structs map[string]ast.StructDeclarationStatement = map[string]ast.StructDeclarationStatement{}
        statements []ast.Statement
        write_structs bool
}

pub fn (mut parser Parser) parse() AST {
    parser.statements << parser.statements()
    ast := AST{"TopLevel", parser.statements}
    return ast
}

fn (mut parser Parser) statements() []Statement {
    mut statements := []Statement{}
    for parser.lookahead().kind != .eof {
        next := parser.statement()
        if parser.write_structs {
            for _, v in parser.structs {
                println("Adding structs")
                statements << v
            }
            parser.structs = map{}
            parser.write_structs = false
        }
        statements << next
    }
    return statements
}

fn (mut parser Parser) statement() Statement {
    mut node := ast.Statement{}
    match parser.lookahead().kind {
        .kw_for {
            // TODO: handle cases like this
            panic("For not allowed at top level")
        }
        .kw_implement {
            parser.implement_block()
        }
        .raw_crystal_code {
            node = ast.RawCrystalCodeStatement{parser.advance().value}
        }
        .kw_use {
            node = parser.use()
        }
        .kw_fn {
            node = parser.fn_decl()
        }
        .kw_is {
            if parser.lookahead_by(2).kind == .identifier {
                node = parser.module_decl()
                parser.write_structs = true
                println("found module")
            }
        }
        .kw_struct {
            construct := parser.construct()
            println("found struct")
            parser.structs[construct.name] = construct
        }
        else {}
    }

    return node
}

fn (mut parser Parser) expr() Expr {
    mut node := ast.Expr{}

    match parser.lookahead().kind {
        .open_paren {
            node = parser.grouped_expr()
        }
        .close_paren {
            utils.error("Unexpected `)` found.")
        }
        .plus,
        .minus,
        .mod,
        .div,
        .and_and,
        .not,
        .not_equal,
        .equal_equal,
        .less_than,
        .less_than_equal,
        .greater_than,
        .greater_than_equal,
        ._or,
        .comma {
            node = ast.VariableExpr{parser.advance().value}
        }
        .semicolon {
            parser.advance()
        }
        .kw_make {
            parser.expect(.kw_make)
            node = parser.fn_call(true)
        }
        .raw_crystal_code {
            node = ast.RawCrystalCodeExpr{parser.advance().value}
        }
        .open_square {
            node = parser.array()
        }
        .kw_for {
            if parser.lookahead_by(3).kind == .kw_in {
                node = parser.for_in_loop()
            } else {
                node = parser.for_loop()
            }
        }
        .kw_break {
            node = ast.VariableExpr{parser.advance().value}
            parser.expect(.semicolon)
        }
        .kw_if {
            node = parser.if_statement()
        }
        .string {
            node = ast.StringLiteralExpr{parser.lookahead().value, "String"}
            parser.advance()
        }
        .number {
            node = ast.NumberLiteralExpr{strconv.atof64(parser.lookahead().value), "Int"}
            parser.advance()
        }
        .kw_return {
            node = parser.ret()
        }
        .identifier {
            match parser.lookahead_by(2).kind {
                .open_paren {
                    node = parser.fn_call(false)
                }
                .arrow_left {
                    node = parser.array_push()
                }
                .plus_plus {
                    node = parser.increment()
                }
                .minus_minus {
                    node = parser.decrement()
                }
                .open_square {
                    node = parser.indexing()
                }
                else {
                    if parser.lookahead_by(2).kind == .equal || parser.lookahead_by(2).kind == .double_colon {
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

    return node
}

fn (mut parser Parser) parse_binary_ops() ast.RawBinaryOpExpr {
    mut raw_op := []string{}
    raw_op << parser.peek().value

    for parser.lookahead().kind != .semicolon {
        next := parser.advance()
        mut val := next.value

        if next.kind == .string {
            val = "\"$val\""
        }

        if val == "," || val == "{" {
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

    if raw_op[0] == "=" || is_keyword(raw_op[0]) {
        raw_op[0] = ""
    }

    return ast.RawBinaryOpExpr{raw_op.join("").replace("Self.", "@")}
}

// Function Declarations
fn (mut parser Parser) fn_decl() ast.FunctionDeclarationStatement {
    parser.expect(.kw_fn)
    fn_name := parser.expect(.identifier).value
    gen_type := parser.generic()
    parser.expect(.open_paren)
    mut args := []ast.FunctionArgument{}
    if parser.lookahead().kind == .identifier {
        args = parser.fn_args(.close_paren)
    }
    parser.expect(.close_paren)
    parser.expect(.double_colon)

    mut is_arr := false
    if parser.lookahead().kind == .open_square {
        is_arr = true
        parser.expect(.open_square)
        parser.expect(.close_square)
    }

    mut ret_type := parser.expect(.identifier).value
    if is_arr {
        ret_type = "Array($ret_type)"
    }
    println(ret_type)
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
        is_struct: false,
        gen_type: gen_type
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
    mut is_arr := false

    if parser.lookahead().kind == .open_square {
        is_arr = true
        parser.expect(.open_square)
        parser.expect(.close_square)
    }
    mut type_name := parser.expect(.identifier).value
    if is_arr {
        type_name = "Array($type_name)"
    }

    return ast.FunctionArgument {
        name: name,
        type_name: type_name
    }
}

fn (mut parser Parser) check_for_binary_ops(lookahead_by_amount int) bool {
    mut raw_op := []string{}
    raw_op << parser.peek().value
    if parser.lookahead_by(lookahead_by_amount).kind in [
        .plus,
        .minus,
        .mod,
        .div,
        .and_and,
        .not,
        .not_equal,
        .equal_equal,
        .less_than,
        .less_than_equal,
        .greater_than,
        .greater_than_equal] {
            return true
    }

    return false
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
            mut value := []ast.Expr{}
            value << ast.VariableExpr{"self"}
            func.body << ast.ReturnExpr{
                value: value,
            }
        }
        func.is_struct = true
    }


    for field in parser.structs[name].fields {
        mut body := []ast.Expr{}
        mut ret := []ast.Expr{}
        ret << ast.VariableExpr{"@$field.name"}
        body << ast.ReturnExpr{ret}
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

fn (mut parser Parser) array_push() Expr {
    target_arr := parser.expect(.identifier).value
    parser.expect(.arrow_left)
    value_to_push := parser.expr()
    parser.expect(.semicolon)

    return ast.ArrayPushExpr {
        target: target_arr,
        value: value_to_push
    }
}

fn (mut parser Parser) for_loop() Expr {
    parser.expect(.kw_for)
    conditional := parser.expr()
    mut body := []Expr{}
    parser.expect(.open_curly)

    for parser.lookahead().kind != .close_curly {
        body_expr := parser.expr()
        if body_expr is ast.NoOp {
            break
        }
        body << body_expr
    }

    parser.expect(.close_curly)

    return ast.ForLoopExpr{
        conditional: conditional,
        body: body
    }
}

fn (mut parser Parser) for_in_loop() Expr {
    parser.expect(.kw_for)
    container := parser.expect(.identifier).value
    parser.expect(.kw_in)
    target := parser.expr()
    mut body := []Expr{}
    parser.expect(.open_curly)

    for parser.lookahead().kind != .close_curly {
        body_expr := parser.expr()
        if body_expr is ast.NoOp {
            break
        }
        body << body_expr
    }

    parser.expect(.close_curly)

    return ast.ForInLoopExpr{
        container: container,
        target: target,
        body: body
    }
}

fn (mut parser Parser) fn_call(is_struct_initializer bool) Expr {
    mut fn_name := parser.expect(.identifier).value
    gen_type := parser.generic()
    parser.expect(.open_paren)
    mut args := []Expr{}

    if is_struct_initializer {
        fn_name = "${fn_name}.new"
    }
    // no args passed
    if parser.lookahead().kind == .close_paren {
        parser.advance()
        return ast.FunctionCallExpr{
            name: fn_name,
            args: []ast.Expr{},
            gen_type: gen_type
        }
    }

    for parser.lookahead().kind != .close_paren {
        args << parser.expr()
    }

    parser.expect(.close_paren)

    // TODO add binary ops
    if parser.lookahead().kind != .close_paren && parser.lookahead().kind != .open_curly && !is_binary_op(parser.lookahead()) {
        parser.expect(.semicolon)
    }

    return ast.FunctionCallExpr{
        name: fn_name,
        args: args
    }
}

fn (mut parser Parser) array() Expr {
    mut items := []Expr{}

    parser.expect(.open_square)
    parser.expect(.close_square)
    type_name := parser.expect(.identifier).value
    parser.expect(.open_curly)
    for parser.lookahead().kind != .close_curly {
        items << parser.expr()
        if parser.lookahead().kind != .close_curly {
            parser.expect(.comma)
        }
    }

    if parser.lookahead().kind != .close_paren {
        parser.expect(.close_curly)
    }
    return ast.ArrayDefinition {
        type_name: type_name,
        items: items
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

fn (mut parser Parser) generic() string {
    mut gen_type := ""
    if parser.lookahead().kind == .less_than {
        parser.expect(.less_than)
        for parser.lookahead().kind != .greater_than {
            if parser.lookahead().kind == .identifier {
                gen_type += parser.expect(.identifier).value
            } else if parser.lookahead().kind == .comma {
                gen_type += parser.expect(.comma).value
            } else {
                break
            }
        }
        parser.expect(.greater_than)
    }

    return gen_type
}

fn (mut parser Parser) construct() ast.StructDeclarationStatement {
    parser.expect(.kw_struct)
    struct_name := parser.expect(.identifier).value

    gen_type := parser.generic()

    parser.expect(.open_curly)
    fields := parser.fn_args(.close_curly)
    parser.expect(.close_curly)

    return ast.StructDeclarationStatement{
        name: struct_name,
        fields: fields,
        fns: []ast.FunctionDeclarationStatement{},
        gen_type: gen_type
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
    mut value := []Expr{}

    for parser.lookahead().kind != .semicolon {
        next := parser.expr()
        value << next
        if next is ast.NoOp {
            break
        }
    }

    return ast.ReturnExpr{
        value: value,
    }
}

fn (mut parser Parser) variable_decl() Expr {
    name := parser.expect(.identifier).value
    mut type_name := ""
    if parser.lookahead().kind == .double_colon {
        parser.expect(.double_colon)
        type_name = parser.expect(.identifier).value
    }
    parser.expect(.equal)

    mut body := []Expr{}
    for parser.lookahead_by(0).kind != .semicolon {
        next := parser.expr()
        body << next
        if next is ast.NoOp {
            break
        }
    }

    return ast.VariableDecl {
        name: name,
        value: body,
        type_name: type_name,
    }
}

fn (mut parser Parser) if_statement() Expr {
    parser.expect(.kw_if)
    conditional := parser.expr()
    parser.expect(.open_curly)
    mut body := []Expr{}
    mut else_body := []Expr{}

    for parser.lookahead().kind != .close_curly {
        body << parser.expr()
    }

    parser.expect(.close_curly)
    mut elseifs := []ast.IfExpression{}
    if parser.lookahead().kind == .kw_elif {
        for parser.lookahead().kind == .kw_elif {
            parser.expect(.kw_elif)
            elseif_conditional := parser.expr()
            parser.expect(.open_curly)
            mut elseif_body := []Expr{}

            for parser.lookahead().kind != .close_curly {
                elseif_body << parser.expr()
            }
            parser.expect(.close_curly)
            elseif_expr := ast.IfExpression{
                conditional: elseif_conditional,
                body: elseif_body,
                else_branch: []Expr{}
            }
            elseifs << elseif_expr
        }
    }

    if parser.lookahead().kind == .kw_else {
        parser.expect(.kw_else)
        parser.expect(.open_curly)
        for parser.lookahead().kind != .close_curly {
            else_body << parser.expr()
        }
        parser.expect(.close_curly)
    }

    return ast.IfExpression{
        conditional: conditional,
        body: body,
        elseifs: elseifs,
        else_branch: else_body
    }
}

fn (mut parser Parser) increment() ast.IncrementExpr {
    target := parser.expect(.identifier).value
    parser.expect(.plus_plus)
    parser.expect(.semicolon)
    return ast.IncrementExpr {
        target: target
    }
}

fn (mut parser Parser) decrement() ast.DecrementExpr {
    target := parser.expect(.identifier).value
    parser.expect(.minus_minus)
    parser.expect(.semicolon)
    return ast.DecrementExpr {
        target: target
    }
}

fn (mut parser Parser) indexing() ast.IndexingExpr {
    var_name := parser.expect(.identifier).value
    parser.expect(.open_square)
    body := parser.expr()
    parser.expect(.close_square)

    return ast.IndexingExpr{
        var: var_name,
        body: body
    }
}

fn (mut parser Parser) grouped_expr() ast.GroupedExpr {
    parser.expect(.open_paren)
    mut body := []ast.Expr{}

    for parser.lookahead().kind != .close_paren {
        body << parser.expr()
    }

    parser.expect(.close_paren)
    return ast.GroupedExpr{body}
}