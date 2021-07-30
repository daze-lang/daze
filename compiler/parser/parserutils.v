module parser

import term

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

    err_msg := term.bold(term.white("Unexpected token: ${next.kind}, expected: ${kind}."))
    line_info := term.bold(term.yellow("(line ${next.line}, col $next.column)"))
    println("${term.bold(term.red("ERROR: $err_msg $line_info"))}")
    exit(1)
}