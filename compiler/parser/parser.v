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
        statements []ast.Statement
    filepath string
}

pub fn new(tokens []Token, filepath string) Parser {
    return Parser{
        tokens,
        -1,
        Token{},
        Token{},
        []ast.Statement{},
        filepath
    }
}

pub fn (mut parser Parser) parse() AST {
    parser.statements << parser.statements()
    ast := AST{"TopLevel", parser.statements}
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
        .kw_for {
            // TODO: handle cases like this
            panic("For not allowed at top level")
        }
        .kw_global { node = parser.global() }
        .raw_cpp_code { node = ast.RawCppCode{body: parser.advance().value} }
        .kw_enum { node = parser.enum_() }
        .kw_use { node = parser.use() }
        .comment { node = ast.Comment{value: parser.advance().value} }
        .kw_fn { node = parser.fn_decl() }
        .kw_is {
            if parser.lookahead_by(2).kind == .identifier {
                node = parser.module_decl()
            }
        }
        .kw_struct { node = parser.construct() }
        else {}
    }
    return node
}

fn (mut parser Parser) expr() Expr {
    mut node := ast.Expr(ast.NoOp{})

    match parser.lookahead().kind {
        .open_curly {
            if parser.lookahead_by(3).kind == .arrow_right {
                node = parser.map_init()
            } else {
                node = parser.array_init()
            }
        }
        .comment { node = ast.Comment{value: parser.advance().value} }
        .open_paren { node = parser.grouped_expr() }
        .raw_cpp_code { node = ast.RawCppCode{body: parser.advance().value} }
        .close_paren { utils.error("Unexpected `)` found.") }
        .comma { node = ast.NoOp{} parser.advance() }
        .semicolon { parser.advance() }
        .kw_make {
            node = parser.struct_new()
        }
        .kw_try {
            node = parser.try()
        }
        .open_square { node = parser.array() }
        .kw_for {
            if parser.lookahead_by(3).kind == .kw_in {
                node = parser.for_in_loop()
            } else {
                node = parser.for_loop()
            }
        }
        .kw_break {
            node = ast.VariableExpr{parser.advance().value + ";"}
            parser.expect(.semicolon)
        }
        .kw_if { node = parser.if_statement() }
        .string {
            node = ast.StringLiteralExpr{parser.lookahead().value, "String"}
            parser.advance()
        }
        .number {
            node = ast.NumberLiteralExpr{strconv.atof64(parser.lookahead().value), "Int"}
            parser.advance()
        }
        .single_quote {
            parser.advance() // eating single quote
            tok := parser.expect(.identifier)
            character := tok.value
            if character.len != 1 {
                utils.parser_error("Characters must be a single character.", parser.filepath, tok.line, tok.column)
            }
            parser.expect(.single_quote)
            node = ast.CharLiteralExpr{character, "Char"}
        }
        .kw_return { node = parser.ret() }
        .identifier {
            match parser.lookahead_by(2).kind {
                .open_paren {
                    node = parser.fn_call()
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
                    if parser.lookahead_by(2).kind in [.equal, .colon_equal, .double_colon] {
                        node = parser.variable_decl()
                    } else {
                        val := parser.lookahead().value
                        if val.starts_with(".") {
                            // TODO: better error message
                            panic("Directly trying to access struct field. Store it in a variable instead")
                        } else {
                            node = ast.VariableExpr{val}
                            parser.advance()
                        }
                    }
                }
            }
        }
        else { node = ast.NoOp{} }
    }

    if is_binary_op(parser.lookahead()) {
        node = parser.binary(node)
    }

    if parser.lookahead().kind == .kw_as {
        parser.expect(.kw_as)
        type_name := parser.expect(.identifier).value
        return ast.TypeCast {
            value: node,
            type_name: type_name
        }
    }

    return node
}

// Function Declarations
fn (mut parser Parser) fn_decl() ast.FunctionDeclarationStatement {
    parser.expect(.kw_fn)
    mut fn_name := parser.expect(.identifier).value
    gen_type := parser.generic()
    parser.expect(.open_paren)
    mut args := []ast.FunctionArgument{}
    if parser.lookahead().kind == .identifier {
        args = parser.fn_args(.close_paren)
    }

    parser.expect(.close_paren)
    parser.expect(.double_colon)

    mut ret_type := ""
    if parser.lookahead().kind == .open_square {
        ret_type = parser.fn_arg(true, .double_colon).type_name
    } else {
        ret_type = parser.expect(.identifier).value
    }

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
        gen_type: gen_type,
    }
}

fn (mut parser Parser) fn_args(delim lexer.TokenType) []ast.FunctionArgument {
    mut args := []ast.FunctionArgument{}
    for parser.lookahead().kind != delim {
        args << parser.fn_arg(false, .double_colon)

        if parser.lookahead().kind != delim {
            if parser.lookahead().kind == .kw_fn {
                return args
            }
            parser.expect(.comma)
        }
    }

    return args
}

fn (mut parser Parser) fn_arg(is_decl bool, delim lexer.TokenType) ast.FunctionArgument {
    mut name := ""
    if !is_decl {
        name = parser.expect(.identifier).value
        parser.expect(delim)
    }

    mut type_name := ""
    mut level := 1
    if parser.lookahead().kind == .kw_map {
        parser.expect(.kw_map)
        parser.expect(.open_square)
        key_type := parser.fn_arg(true, .arrow_right).type_name
        parser.expect(.arrow_right)
        value_type := parser.fn_arg(true, .arrow_right).type_name
        parser.expect(.close_square)
        type_name = "$key_type->$value_type"

        return ast.FunctionArgument {
            name: name,
            type_name: type_name.replace(":", "::")
        }
    }

    // if we are trying to parse an array type
    if parser.lookahead().kind == .open_square {
        parser.expect(.open_square)
        for parser.lookahead().kind == .open_square {
            parser.expect(.open_square)
            level++
        }
        type_name = parser.expect(.identifier).value
        for _ in 0..level {
            parser.expect(.close_square)
        }
        type_name += "|${level}"
    } else {
        mut is_ref := false
        if parser.lookahead().value == "ref" {
            parser.advance()
            is_ref = true
        }
        type_name = parser.expect(.identifier).value
        if is_ref {
            type_name = "ref $type_name"
        }
    }

    return ast.FunctionArgument {
        name: name,
        type_name: type_name.replace(":", "::")
    }
}

fn (mut parser Parser) array_push() ast.ArrayPushExpr {
    target_arr := parser.expect(.identifier).value
    parser.expect(.arrow_left)
    value_to_push := parser.expr()
    parser.expect(.semicolon)

    return ast.ArrayPushExpr {
        target: target_arr,
        value: value_to_push
    }
}

fn (mut parser Parser) for_loop() ast.ForLoopExpr {
    parser.expect(.kw_for)
    mut conditional := parser.expr()
    parser.expect(.open_curly)

    mut body := []Expr{}

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

fn (mut parser Parser) for_in_loop() ast.ForInLoopExpr {
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

fn (mut parser Parser) fn_call() ast.FunctionCallExpr {
    tok := parser.expect(.identifier)
    mut fn_name := tok.value

    parser.expect(.open_paren)
    mut args := []Expr{}
    mut callchain := fn_name.split(".")

    // no args passed
    if parser.lookahead().kind == .close_paren {
        parser.advance()
        return ast.FunctionCallExpr{
            name: fn_name,
            callchain: callchain,
            args: []ast.Expr{},
        }
    }

    for parser.lookahead().kind != .close_paren {
        args << parser.expr()

        if parser.lookahead().kind == .comma {
            parser.advance()
        }
    }

    parser.expect(.close_paren)

    if parser.lookahead().kind !in [.close_paren, .open_curly] && !is_binary_op(parser.lookahead()) {
        parser.expect(.semicolon)
    }


    return ast.FunctionCallExpr{
        name: fn_name,
        args: args
    }
}

fn (mut parser Parser) array() ast.ArrayDefinition {
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

fn (mut parser Parser) module_decl() ast.ModuleDeclarationStatement {
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
    parser.expect(.open_curly)
    mut fields := []ast.FunctionArgument{}
    if parser.lookahead().kind != .kw_fn {
        fields = parser.fn_args(.close_curly)
    }

    mut member_fns := []ast.FunctionDeclarationStatement{}
    for parser.lookahead().kind != .close_curly {
        member_fns << parser.fn_decl()
    }
    parser.expect(.close_curly)

    return ast.StructDeclarationStatement{
        name: struct_name,
        fields: fields,
        member_fns: member_fns
    }
}

fn (mut parser Parser) use() ast.ModuleUseStatement {
    parser.expect(.kw_use)
    path := parser.expect(.string).value
    parser.expect(.semicolon)

    return ast.ModuleUseStatement{
        path: path
    }
}

fn (mut parser Parser) ret() ast.ReturnExpr {
    parser.expect(.kw_return)

    return ast.ReturnExpr{
        value: parser.expr(),
    }
}

fn (mut parser Parser) variable_decl() Expr {
    id := parser.expect(.identifier)
    name := id.value
    // TODO: move this to the type checker
    if name == name.capitalize() {
        utils.parser_error("Variables are not allowed to start with a capital letter.", parser.filepath, id.line, id.column)
    }

    mut type_name := ""
    mut is_reassignment := false
    mut is_auto := false
    if parser.lookahead().kind == .double_colon {
        parser.expect(.double_colon)
        type_name = parser.fn_arg(true, .double_colon).type_name
        parser.expect(.colon_equal)
    } else {
        if parser.lookahead().kind == .colon_equal {
            is_auto = true
            parser.expect(.colon_equal)
        } else {
            is_reassignment = true
            parser.expect(.equal)
        }
    }

    mut body := parser.expr()

    // var = "some string";
    if is_reassignment {
        return ast.VariableAssignment {
            name: name,
            value: body,
        }
    }

    // var := "some string";
    if is_auto {
        return ast.VariableDecl {
            name: name,
            value: body,
            type_name: type_name
        }
    }

    // var :: String := "some_string";
    return ast.VariableDecl {
        name: name,
        value: body,
        type_name: type_name,
    }
}

fn (mut parser Parser) if_statement() ast.IfExpression {
    parser.expect(.kw_if)
    mut conditional := parser.expr()
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
            mut elseif_conditional := parser.expr()
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
    mut body := parser.expr()
    parser.expect(.close_paren)
    return ast.GroupedExpr{body}
}

fn (mut parser Parser) array_init() ast.ArrayInit {
    parser.expect(.open_curly)
    mut body := []ast.Expr{}

    for parser.lookahead().kind != .close_curly {
        body << parser.expr()
    }

    parser.expect(.close_curly)
    return ast.ArrayInit{body}
}

fn (mut parser Parser) map_init() ast.MapInit {
    parser.expect(.open_curly)
    mut body := []ast.MapKeyValuePair{}

    for parser.lookahead().kind != .close_curly {
        key := parser.expr()
        if key is ast.NoOp {
            continue
        }
        parser.expect(.arrow_right)
        value := parser.expr()
        if value is ast.NoOp {
            continue
        }
        body << ast.MapKeyValuePair{key: key, value: value}
    }

    parser.expect(.close_curly)
    return ast.MapInit{body}
}

fn (mut parser Parser) global() ast.GlobalDecl {
    parser.expect(.kw_global)
    name := parser.expect(.identifier).value
    parser.expect(.equal)
    value := parser.expr()
    parser.expect(.semicolon)

    return ast.GlobalDecl{
        name: name,
        value: value
    }
}

fn (mut parser Parser) struct_new() ast.StructInitialization {
    parser.expect(.kw_make)
    struct_name := parser.expect(.identifier).value
    parser.expect(.open_paren)
    mut args := []ast.Expr{}
    for parser.lookahead().kind != .close_paren {
        args << parser.expr()
    }
    parser.expect(.close_paren)

    return ast.StructInitialization{
        name: struct_name,
        args: args
    }
}

fn (mut parser Parser) try() ast.OptionalFunctionCall {
    parser.expect(.kw_try)
    fn_call := parser.expr()
    if fn_call !is ast.FunctionCallExpr {
        // TODO: move error message to checker
        panic("Only function calls can be used in try blocks.")
    }

    parser.expect(.kw_or)
    default := parser.expr()
    parser.expect(.semicolon)

    return ast.OptionalFunctionCall{
        fn_call: fn_call,
        default: default
    }
}

fn (mut parser Parser) binary(node ast.Expr) ast.BinaryOperation {
    lhs := node
    mut op := ""
    mut rhs := ast.Expr{}

    if is_binary_op(parser.lookahead()) {
        op = parser.advance().value
        rhs = parser.expr()
        if is_binary_op(parser.lookahead()) {
            rhs = parser.binary(rhs)
        }

        return ast.BinaryOperation{
            lhs: lhs,
            op: op,
            rhs: rhs
        }
    }

    // Unreachable
    return ast.BinaryOperation{}
}

fn (mut parser Parser) enum_() ast.EnumDeclarationStatement {
    parser.expect(.kw_enum)
    name := parser.expect(.identifier).value
    parser.expect(.open_curly)
    mut values := []string{}
    for parser.lookahead().kind != .close_curly {
        values << parser.expect(.identifier).value

        if parser.lookahead().kind != .close_curly {
            parser.expect(.comma)
        }
    }

    parser.expect(.close_curly)
    parser.expect(.semicolon)

    return ast.EnumDeclarationStatement{
        name: name,
        values: values
    }
}