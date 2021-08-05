module main

import os
import pcre

import lexer{Token}
import ast
import parser
import checker
import codegen
import utils

fn match_all(text string, regexp string) []string {
    mut matches := []string{}
    mut str_copy := text

    mut re := pcre.new_regex(regexp, 0) or { panic(err) }

    for {
        m := re.match_str(str_copy, 0, 0) or { break }
        matched := m.get(0) or { break }
        str_copy = str_copy.replace_once(matched, '')
        matches << matched
    }

    return matches
}

fn load_imports(code string) ?[]string {
    matches := match_all(code, "use (.*?);")
    mut compiled_modules := []string{}

    for m in matches {
        mut module_path := m.replace("\"", "").replace("use ", "").replace(";", "")
        if module_path.starts_with("daze::") {
            module_name := module_path.replace("daze::", "")
            module_path = "${os.getenv("DAZE_PATH")}/stdlib/$module_name"
            if module_name != module_name.capitalize() {
                utils.error("Module name should be capitalized.")
            }
        }


        mut module_file := os.read_file("${module_path}.daze") or { panic("File not found") }
        compiled_modules << module_file
        compiled_modules << load_imports(module_file)?
    }

    return compiled_modules
}

fn to_crystal(source string) ?string {
    mut lexer := lexer.Lexer{input: source.split('')}
    tokens := lexer.lex()?
    mut parser := parser.Parser{
        tokens,
        -1,
        Token{},
        Token{},
        []ast.Statement,
    }
    ast := parser.parse()
    // panic(ast)

    mut checker := checker.Checker{
        ast,
        map[string]ast.FunctionDeclarationStatement,
        map[string]ast.StructDeclarationStatement{},
        map[string]ast.VariableDecl{},
        []string{}
    }
    // checker.run()
    mut codegen := codegen.CodeGenerator{ast, 0, []string{}, 0}
    mut code := codegen.run()
    return code
}

fn compile(code string) {
    os.write_file("/tmp/lang.cr", code) or { panic("Failed writing file") }
    // os.execute("crystal tool format /tmp/lang.cr")
    println(os.execute("crystal build /tmp/lang.cr").output)
    println("==========================================")
}

fn main() {
    mut input_file := os.read_file("demo/lang.daze") or { panic("File not found") }
    compiled_modules := load_imports(input_file)?

    mut source := ""
    for mod in compiled_modules {
        source += "\n$mod\n\n"
    }
    source += input_file
    mut stripped_comments := ""
    lines := source.split("\n")
    for line in lines {
        if !line.starts_with("#") {
            stripped_comments += "${line}\n"
        }
    }
    // panic(stripped_comments)
    code := to_crystal(stripped_comments)?

    mut builtin_file := os.read_file("compiler/builtins/types.cr") or { panic("File not found") }
    compile(builtin_file + "\n" + code)
    // compile(code)
}