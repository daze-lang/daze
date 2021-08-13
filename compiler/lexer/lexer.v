module lexer

pub struct Lexer {
    input []string [required]
    mut:
        index int
        line int
        column int
}

pub fn new(source string) Lexer {
    return Lexer{
        source.split(""),
        -1,
        1,
        0
    }
}

pub fn (mut lexer Lexer) lex() ?[]Token {
    mut tokens := []Token{}

    for {
        if lexer.lookahead() == "EOF" {
            tokens << Token{.eof, "EOF", lexer.line, lexer.column}
            break
        }

        current := lexer.advance()

        // Skipping whitespace
        if lexer.is_whitespace(current) || current == "\n" {
            continue
        }

        match current {
            "(" {
                tokens << Token{.open_paren, current, lexer.line, lexer.column}
                continue
            }
            ")" {
                tokens << Token{.close_paren, current, lexer.line, lexer.column}
                continue
            }
            "{" {
                tokens << Token{.open_curly, current, lexer.line, lexer.column}
                continue
            }
            "}" {
                tokens << Token{.close_curly, current, lexer.line, lexer.column}
                continue
            }
            // "@" {
            //     tokens << Token{.at, current, lexer.line, lexer.column}
            //     continue
            // }
            ";" {
                tokens << Token{.semicolon, current, lexer.line, lexer.column}
                continue
            }
            "," {
                tokens << Token{.comma, current, lexer.line, lexer.column}
                continue
            }
            "|" {
                if lexer.lookahead() == "|" {
                    tokens << Token{._or, "||", lexer.line, lexer.column}
                    lexer.advance()
                } else if lexer.lookahead() == ">" {
                    tokens << Token{.pipe, "|>", lexer.line, lexer.column}
                    lexer.advance()
                }
                continue
            }
            "+" {
                if lexer.lookahead() == "+" {
                    tokens << Token{.plus_plus, "++", lexer.line, lexer.column}
                    lexer.advance()
                } else {
                    tokens << Token{.plus, current, lexer.line, lexer.column}
                }
                continue
            }
            "-" {
                if lexer.lookahead() == "-" {
                    tokens << Token{.minus_minus, "--", lexer.line, lexer.column}
                    lexer.advance()
                } else {
                    tokens << Token{.minus, current, lexer.line, lexer.column}
                }
                continue
            }
            "/" {
                tokens << Token{.div, current, lexer.line, lexer.column}
                continue
            }
            "%" {
                tokens << Token{.mod, current, lexer.line, lexer.column}
                continue
            }
            "'" {
                tokens << Token{.single_quote, current, lexer.line, lexer.column}
                continue
            }
            // "[" {
            //     tokens << Token{.open_square, current, lexer.line, lexer.column}
            //     continue
            // }
            // "]" {
            //     tokens << Token{.close_square, current, lexer.line, lexer.column}
            //     continue
            // }
            "<" {
                if lexer.lookahead() == "=" {
                    tokens << Token{.less_than_equal, "<=", lexer.line, lexer.column}
                    lexer.advance()
                } else if lexer.lookahead() == "-" {
                    tokens << Token{.arrow_left, "<-", lexer.line, lexer.column}
                    lexer.advance()
                } else {
                    tokens << Token{.less_than, current, lexer.line, lexer.column}
                }
                continue
            }
            ">" {
                if lexer.lookahead() == "=" {
                    tokens << Token{.greater_than_equal, ">=", lexer.line, lexer.column}
                    lexer.advance()
                } else {
                    tokens << Token{.greater_than, current, lexer.line, lexer.column}
                }
                continue
            }
            "=" {
                if lexer.lookahead() == "=" {
                    tokens << Token{.equal_equal, "==", lexer.line, lexer.column}
                    lexer.advance()
                } else {
                    tokens << Token{.equal, current, lexer.line, lexer.column}
                }
                continue
            }
            "&" {
                if lexer.lookahead() == "&" {
                    tokens << Token{.and_and, "&&", lexer.line, lexer.column}
                    lexer.advance()
                }
                continue
            }
            "!" {
                if lexer.lookahead() == "=" {
                    tokens << Token{.not_equal, "!=", lexer.line, lexer.column}
                    lexer.advance()
                } else {
                    tokens << Token{.not, "!", lexer.line, lexer.column}
                }
                continue
            }
            ":" {
                if lexer.lookahead() == ":" {
                    tokens << Token{.double_colon, "::", lexer.line, lexer.column}
                    lexer.advance()
                } else if lexer.lookahead() == "=" {
                    tokens << Token{.colon_equal, ":=", lexer.line, lexer.column}
                    lexer.advance()
                } else {
                    tokens << Token{.colon, current, lexer.line, lexer.column}
                }
                continue
            }
            else {}
        }

        if !lexer.is_number(current) || current == "." {
            if current != "\"" {
                id := lexer.read_identifier(current)
                // We check if its a valid keyword, if so, we set the token kind
                kind := to_keyword(id) or { TokenType.identifier }
                tokens << Token{kind, id, lexer.line, lexer.column}
                continue
            } else if current == "." {
                tokens << Token{.dot, ".", lexer.line, lexer.column}
            }
        }

        if lexer.is_number(current) && current != "." {
            tokens << Token{.number, lexer.read_number(current)?, lexer.line, lexer.column}
            continue
        }

        if current == "\"" {
            if lexer.lookahead() == "\"" {
                lexer.advance()
                tokens << Token{.string, "", lexer.line, lexer.column}
            } else {
                tokens << Token{.string, lexer.read_string(), lexer.line, lexer.column}
            }
            continue
        }

        if lexer.index == lexer.input.len - 1 {
            break
        }
    }

    return tokens
}