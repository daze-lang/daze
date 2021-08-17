module lexer

import strconv

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

fn (lexer Lexer) lookahead_by(amount int) string {
    if lexer.index >= lexer.input.len - 1{
        return "EOF"
    }
    return lexer.input[lexer.index + amount]
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

fn (mut lexer Lexer) read_number(c string) string {
    mut raw_num := c
    for lexer.is_number(lexer.lookahead()) {
        raw_num += lexer.advance()
    }

    return raw_num
}

fn (lexer Lexer) is_whitespace(c string) bool {
    return c == " " || c == "\t"
}

fn (lexer Lexer) is_number(c string) bool {
    strconv.atoi(c) or {
        if c == "." {
            return true
        }
        return false
    }
    return true
}

fn (lexer Lexer) is_letter(c string) bool {
    return "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_.@?:".contains(c)
}

pub fn to_string(kw TokenType) string {
    if kw.str().contains("kw_") {
        for key, tk_type in keywords_map {
            if tk_type == kw {
                return key
            }
        }
    }

    return lexer.tokens_map[kw.str()] or { kw.str() }
}

pub fn is_keyword(id string) bool {
    return keywords_map.keys().contains(id)
}

pub fn to_keyword(id string) ?TokenType {
    return keywords_map[id] or {
        return error("Not a keyword.")
    }
}