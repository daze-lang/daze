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

// compiles down daze source code to crystal
fn to_crystal(source string) ?string {
    mut lexer := lexer.new(source)
    tokens := lexer.lex()?
    mut parser := parser.new(tokens)
    ast := parser.parse()
    // panic(ast)

    mut checker := checker.new(ast)
    checker.run()
    // mut codegen := codegen.new_crystal(ast)
    mut codegen := codegen.new_c(ast)
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

fn crystal(file_name string, code string) {
    os.write_file("/tmp/daze/${file_name}.cr", code) or { panic("Failed writing file") }
    println(os.execute("crystal build /tmp/daze/${file_name}.cr").output)
}

fn c(file_name string, code string) {
    os.write_file("/tmp/daze/${file_name}.c", code) or { panic("Failed writing file") }
    println(os.execute("gcc /tmp/daze/${file_name}.c /tmp/daze/tgc.c -o ./$file_name").output)
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
    code := to_crystal(strip_comments(source))?
    output_file_name := os.file_name(path).replace(".daze", "")

    // crystal(output_file_name, code)
    c(output_file_name, code)
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