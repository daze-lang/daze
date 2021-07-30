module parser

import lexer{Token, TokenType}

pub fn (mut parser Parser) advance() Token {
    parser.index++
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
    if parser.lookahead().kind == kind {
        return parser.advance()
    }

    panic("Unexpected token ${parser.lookahead().kind}, expected ${kind}")
}