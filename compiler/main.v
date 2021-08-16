module main

import os
import term

import lexer{Token}
import parser
import checker
import codegen
import utils

// loading and adding module files recursively
fn load_modules(code string) ?[]string {
    matches := utils.match_all(code, "use (.*?);")
    mut modules := []string{}

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
        modules << module_file
        modules << load_modules(module_file)?
    }

    return modules
}

// compiles down daze source code to cpp
fn to_cpp(source string, path string) string {
    mut lexer := lexer.new(source)
    tokens := lexer.lex()
    mut parser := parser.new(tokens, path)
    ast := parser.parse()

    mut checker := checker.new(ast)
    checker.run()
    mut codegen := codegen.new_cpp(ast)
    mut code := codegen.run()
    // panic(code)
    return code
}

fn cpp(file_name string, code string) {
    os.write_file("/tmp/daze/${file_name}.cpp", code) or { panic("Failed writing file") }
    println(os.execute("gcc -x c++ /tmp/daze/${file_name}.cpp -o $file_name -lstdc++").output)
}

// compiles the main entry point & writes it to file
fn compile_main(path string) ? {
    mut input_file := os.read_file(path) or { panic("File not found") }
    modules := load_modules(input_file)?

    mut source := ""
    for mod in modules {
        source += "\n$mod\n\n"
    }

    source += input_file
    code := to_cpp(source, path)
    output_file_name := os.file_name(path).replace(".daze", "")

    cpp(output_file_name, code)
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
            if os.args.len != 3 {
                utils.error("Too few arguments for command `build`.")
            }

            compile_main(os.args[2])?
        }

        "run" {
            if os.args.len != 3 {
                utils.error("Too few arguments for command `run`.")
            }

            compile_main(os.args[2])?
            executable := os.file_name(os.args[2]).replace(".daze", "")
            println(os.execute("./${executable}").output)
        }

        else {
            help()
        }
    }
}