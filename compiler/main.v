module main

import os
import term
import utils
import ast
import cli

fn write_generated_output(file_name string, code string) {
    os.write_file("/tmp/daze/${file_name}.cpp", code) or { panic("Failed writing file") }
    os.execute("astyle /tmp/daze/${file_name}.cpp")
    include_dir := "${os.getenv("DAZE_PATH")}/compiler/include"
    command_args := [
        "gcc -x c++ /tmp/daze/${file_name}.cpp -o $file_name",
        "-lstdc++",
        "-I$include_dir",
        "-static",
        "-fno-diagnostics-show-caret -fdiagnostics-color=always"
    ]
    result := os.execute(command_args.join(" "))
    if result.exit_code != 0 {
        println(term.red(term.bold("Compiler error. The C++ Compiler failed.")))
        println(term.red(term.bold("========================================")))
        println("")
        println(result.output)
    }
}

// compiles the main entry point & writes it to file
fn compile_main(path string, base string) ? {
    mut main_module_contents := os.read_file(path) or { panic("(main) File not found") }
    // TODO: not a good way to do things
    mut header := os.read_file(os.getenv("DAZE_PATH") + "/compiler/include/header.h") or { panic("File not found") }
    mut httplib := os.read_file(os.getenv("DAZE_PATH") + "/compiler/include/httplib.h") or { panic("File not found") }

    main_module := ast.Module{
        name: "main",
        path: path,
        code: main_module_contents
    }

    result := cli.compile(main_module, base)
    output_file_name := os.file_name(path).replace(".daze", "")
    write_generated_output(output_file_name, header + httplib + result.code)
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
            compile_main(os.args[2], get_base_dir(os.args[2]))?
        }

        "run" {
            if os.args.len != 3 {
                utils.error("Too few arguments for command `run`.")
            }
            compile_main(os.args[2], get_base_dir(os.args[2]))?
            executable := os.file_name(os.args[2]).replace(".daze", "")
            println(os.execute("./${executable}").output)
        }

        else {
            help()
        }
    }
}

fn get_base_dir(path string) string {
    parts := path.split("/")
    parts.pop()
    base := os.join_path(os.getwd(), parts.join("/")) + "/"
    return base
}