module main

import lexer{Token}
import parser
import os

fn main() {
    mut input_file := os.read_file('lang.dz') or { panic('File not found') }
    chars := input_file.split('')

    mut lexer := lexer.Lexer{input: chars}
    tokens := lexer.lex()?
    mut parser := parser.Parser{tokens, -1, Token{}, Token{}}
    ast := parser.parse()
    println(ast)
}