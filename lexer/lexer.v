module lexer

import strconv

pub struct Lexer {
    input []string [required]
    mut:
        index int = -1
        line int = 1
        column int
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
            "@" {
                tokens << Token{.at, current, lexer.line, lexer.column}
                continue
            }
            ";" {
                tokens << Token{.semicolon, current, lexer.line, lexer.column}
                continue
            }
            "," {
                tokens << Token{.comma, current, lexer.line, lexer.column}
                continue
            }
            "+" {
                tokens << Token{.plus, current, lexer.line, lexer.column}
                continue
            }
            "-" {
                tokens << Token{.minus, current, lexer.line, lexer.column}
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

        if !lexer.is_number(current) {
            if current != "\"" {
                id := lexer.read_identifier(current)
                // We check if its a valid keyword, if so, we set the token kind
                kind := to_keyword(id) or { TokenType.identifier }
                tokens << Token{kind, id, lexer.line, lexer.column}
                continue
            }
        }

        if lexer.is_number(current) {
            tokens << Token{.number, lexer.read_number(current)?, lexer.line, lexer.column}
            continue
        }

        if current == "\"" {
            tokens << Token{.string, lexer.read_string(), lexer.line, lexer.column}
            continue
        }

        if lexer.index == lexer.input.len - 1 {
            break
        }
    }

    return tokens
}

fn (mut lexer Lexer) advance() string {
    lexer.index++
    if lexer.input[lexer.index] == "\n" {
        lexer.line++
        lexer.column = 0
    } else {
        lexer.column++
    }
    return lexer.input[lexer.index]
}

fn (lexer Lexer) peek() string {
    return lexer.input[lexer.index]
}

fn (lexer Lexer) lookahead() string {
    if lexer.index >= lexer.input.len - 1{
        return "EOF"
    }
    return lexer.input[lexer.index + 1]
}

fn (mut lexer Lexer) read_identifier(c string) string {
    mut id := c

    for lexer.is_letter(lexer.lookahead()) || lexer.is_number(lexer.lookahead()) {
        if lexer.lookahead() == " " {
            break
        }

        id += lexer.advance()
    }

    return id
}

fn (mut lexer Lexer) read_string() string {
    // Eating opening "
    mut string_in := lexer.advance()

    for lexer.lookahead() != '"' {
        string_in += lexer.advance()
    }

    // Eating closing "
    lexer.advance()
    return string_in
}

fn (mut lexer Lexer) read_number(c string) ?string {
    mut raw_num := c
    for lexer.is_number(lexer.lookahead()) || lexer.lookahead() == "." {
        raw_num += lexer.advance()
    }

    return raw_num
}

fn (lexer Lexer) is_whitespace(c string) bool {
    return c == " " || c == "\t"
}

fn (lexer Lexer) is_number(c string) bool {
    strconv.atoi(c) or { return false }
    return true
}

fn (lexer Lexer) is_letter(c string) bool {
    return "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_.".contains(c)
}