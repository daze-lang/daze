module lexer

import strconv

pub struct Lexer {
    input []string [required]
    mut:
        index int = -1
}

pub fn (mut lexer Lexer) lex() ?[]Token {
    mut tokens := []Token{}

    for {
        if lexer.lookahead() == "EOF" {
            tokens << Token{.eof, "EOF"}
            break
        }

        current := lexer.advance()

        // Skipping whitespace
        if lexer.is_whitespace(current) || current == "\n" {
            continue
        }

        match current {
            "(" {
                tokens << Token{.open_paren, current}
                continue
            }
            ")" {
                tokens << Token{.close_paren, current}
                continue
            }
            "{" {
                tokens << Token{.open_curly, current}
                continue
            }
            "}" {
                tokens << Token{.close_curly, current}
                continue
            }
            "@" {
                tokens << Token{.at, current}
                continue
            }
            ";" {
                tokens << Token{.semicolon, current}
                continue
            }
            "," {
                tokens << Token{.comma, current}
                continue
            }
            ":" {
                if lexer.lookahead() == ":" {
                    tokens << Token{.double_colon, "::"}
                    lexer.advance()
                } else {
                    tokens << Token{.colon, current}
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
                tokens << Token{kind, id}
                continue
            }
        }

        if lexer.is_number(current) {
            tokens << Token{.number, lexer.read_number(current)?}
            continue
        }

        if current == "\"" {
            tokens << Token{.string, lexer.read_string()}
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
    return "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ".contains(c)
}