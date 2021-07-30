module main

import os

import lexer{Token}
import parser
import codegen

fn main() {
    mut input_file := os.read_file('lang.dz') or { panic('File not found') }
    // removing comments
    for line in input_file.split("\n") {
        if line.starts_with("//") {
            input_file = input_file.replace(line, "")
        }
    }
    chars := input_file.split('')

    mut lexer := lexer.Lexer{input: chars}
    tokens := lexer.lex()?
    mut parser := parser.Parser{tokens, -1, Token{}, Token{}}
    ast := parser.parse()
    mut codegen := codegen.CodeGenerator{ast, ""}
    mut result := codegen.run()
    // println(result)

    os.write_file("/tmp/lang.cr", result) or { panic("Failed writing file") }
    os.execute("crystal build /tmp/lang.cr")
}