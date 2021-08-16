module cli

import lexer{Token}
import ast
import parser
import checker
import codegen

pub fn compile(mod Module) CompilationResult {
    mut lexer := lexer.new(mod.code)
    tokens := lexer.lex()
    mut parser := parser.new(tokens, mod.path)
    ast := parser.parse()
    // panic(ast)

    mut codegen := codegen.new_cpp(ast)
    mut code := codegen.run()

    return CompilationResult{
        ast: ast,
        mod: mod,
        code: code
    }
}