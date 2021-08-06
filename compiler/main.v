module main

import os
import term

import lexer{Token}
import ast
import parser
import checker
import codegen
import utils

// loading and adding module files recursively
fn load_imports(code string) ?[]string {
    matches := utils.match_all(code, "use (.*?);")
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

// compiles down daze source code to crystal
fn to_crystal(source string) ?string {
    mut lexer := lexer.Lexer{input: source.split('')}
    tokens := lexer.lex()?
    mut parser := parser.Parser{
        tokens,
        -1,
        Token{},
        Token{},
        []ast.Statement{},
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

// removes comments from daze source code
fn strip_comments(source string) string {
    mut stripped_comments := ""

    lines := source.split("\n")
    for line in lines {
        if !line.starts_with("#") {
            stripped_comments += "${line}\n"
        }
    }

    return stripped_comments
}

// compiles the main entry point & writes it to file
fn compile_main(path string) ? {
    mut input_file := os.read_file(path) or { panic("File not found") }
    compiled_modules := load_imports(input_file)?

    mut source := ""
    for mod in compiled_modules {
        source += "\n$mod\n\n"
    }
    source += input_file
    code := to_crystal(strip_comments(source))?

    output_file_name := os.file_name(path).replace(".daze", "")

    // mut builtin_file := os.read_file("compiler/builtins/types.cr") or { panic("File not found") }
    os.write_file("/tmp/daze/${output_file_name}.cr", code) or { panic("Failed writing file") }
    // os.execute("crystal tool format /tmp/lang.cr")
    println(os.execute("crystal build /tmp/daze/${output_file_name}.cr").output)
    println("==========================================")
}

fn help() {
    println(term.bold(term.bright_blue("Daze Compiler v0.0.1\n")))

    println(term.bold(term.white("Available subcommands:\n")))
    println(" ".repeat(4) + " - build <main_file>       Builds an executable")
    println(" ".repeat(4) + " - run <main_file>         Builds an executable & runs the produced binary")
}

fn main() {
    if os.args.len == 1 {
        help()
        return
    }

    match os.args[1] {
        "build" {
            println(os.args[2])
            compile_main(os.args[2])?
        }
        else {
            help()
        }
    }
}