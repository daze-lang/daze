module parser

import utils

import lexer{Token, TokenType}

pub fn (mut parser Parser) advance() Token {
    parser.index++
    current := parser.current
    parser.current = parser.tokens[parser.index]
    parser.previous = current
    return parser.current
}

pub fn (mut parser Parser) step_back() Token {
    parser.index--
    current := parser.current
    parser.current = parser.tokens[parser.index]
    parser.previous = current
    return parser.current
}

pub fn (mut parser Parser) peek() Token {
    return parser.tokens[parser.index]
}

pub fn (mut parser Parser) lookahead() Token {
    return parser.tokens[parser.index + 1]
}

pub fn (mut parser Parser) lookahead_by(num int) Token {
    return parser.tokens[parser.index + num]
}

pub fn (mut parser Parser) expect(kind TokenType) Token {
    next := parser.lookahead()
    if next.kind == kind {
        return parser.advance()
    }

    found := lexer.to_string(next.kind)
    expected := lexer.to_string(kind)

    utils.syntax_error(found, expected, next.line, next.column, parser.filepath)
    return Token{}
}

pub fn is_binary_op(op Token) bool {
    if op.kind in [
        .plus,
        .minus,
        .mod,
        .div,
        .mul,
        .and_and,
        .not,
        .not_equal,
        .equal_equal,
        .less_than,
        .less_than_equal,
        .greater_than,
        .greater_than_equal,
        ._or] {
            return true
    }

    return false
}