module main

import os

fn main() {
    mut input_file := os.read_file('lang.dz') or { panic('File not found') }
    chars := input_file.split('')

    mut lexer := Lexer{input: chars}
    tokens := lexer.lex()?
    // tokens := "h"
    println(tokens)
}