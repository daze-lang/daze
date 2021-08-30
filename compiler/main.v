module main

import term
import lexer
import parser
import codegen
import checker
import utils
import ast
import os

const __version = "0.0.3"

fn module_not_found(name string, path string) {
    println("Module `$name` not found. Aborting.")
}

fn load_modules(mod ast.Module, base string) []ast.Module {
    matches := utils.match_all(mod.code, "use (.*?\n)")
    mut modules := []ast.Module{}
    for m in matches {
        mut module_path := m.trim_space().replace("\"", "").replace("use ", "").replace(";", "")
        module_name := module_path.replace("daze::", "").replace("::", "/")
        if module_path.starts_with("daze::") {
            module_path = "${os.getenv("DAZE_PATH")}/stdlib/$module_name"
        } else {
            module_path = os.join_path(base, module_path)
        }

        mut module_file := os.read_file("${module_path}.daze") or { module_not_found(module_name, module_path) exit(1) }
        mod_name := module_name.replace("./", "").split("/")
        new_mod := ast.Module{
            name: mod_name.pop(),
            path: module_path + ".daze"
            code: module_file
        }

        modules << new_mod
        modules << load_modules(new_mod, base)
    }

    return modules
}

fn compile_modules(mods []ast.Module, base string) map[string]ast.CompilationResult {
    mut compiled_modules_map := map[string]ast.CompilationResult{}

    for rawmod in mods {
        compiled_modules_map[rawmod.name] = compile(rawmod, base)
    }

    return compiled_modules_map
}

fn replace_imports(code string, lookup map[string]ast.CompilationResult) string {
    mut ret_code := code
    matches := utils.match_all(code, "// MODULE (.*?);")

    for m in matches {
        mod_name := m.replace("// MODULE ", "").replace(";", "")
        ret_code = ret_code.replace(m, lookup[mod_name].code)
        return replace_imports(ret_code, lookup)
    }

    return ret_code
}

pub fn compile(mod ast.Module, base string) ast.CompilationResult {
    mut lexer := lexer.new(mod.code)
    tokens := lexer.lex()
    mut parser := parser.new(tokens, mod.path)
    program_ast := parser.parse()

    mut codegen := codegen.new_cpp(program_ast)
    mut code := codegen.run()

    if mod.name == "main" {
        // panic(program_ast)
        module_lookup := compile_modules(load_modules(mod, base), base)
        mut checker := checker.new(program_ast, module_lookup)
        checker.run()

        return ast.CompilationResult{
            ast: program_ast,
            mod: mod,
            code: replace_imports(code, module_lookup)
        }
    }

    return ast.CompilationResult{
        ast: program_ast,
        mod: mod,
        code: code
    }
}

fn write_generated_output(file_name string, code string) {
    os.write_file("/tmp/daze/${file_name}.cpp", code) or { panic("Failed writing file") }
    os.execute("astyle /tmp/daze/${file_name}.cpp")
    include_dir := "${os.getenv("DAZE_PATH")}/compiler/thirdparty"
    command_args := [
        "gcc -x c++ /tmp/daze/${file_name}.cpp -o $file_name",
        "-lstdc++",
        "-I$include_dir",
        "-static",
        "-fno-diagnostics-show-caret -fdiagnostics-color=always"
    ]
    result := os.execute(command_args.join(" "))
    if result.exit_code != 0 {
        println(term.red(term.bold("Codegen error. The C++ Compiler failed.")))
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

    main_module := ast.Module{
        name: "main",
        path: path,
        code: main_module_contents
    }

    result := compile(main_module, base)
    version_def := "#define __DAZE_VERSION__ ${__version}\n"
    output_file_name := os.file_name(path).replace(".daze", "")
    write_generated_output(output_file_name, version_def + header + result.code)
}

fn help() {
    println(term.bold(term.bright_blue("Daze Compiler v${__version}\n")))
    println(term.bold(term.white("Available subcommands:\n")))
    println(" ".repeat(4) + " - build <main_file>  Builds an executable")
    println(" ".repeat(4) + " - diag               Outputs helpful information about the setup of the Daze Compiler")
    println(" ".repeat(4) + " - version            Outputs the version of the installed Daze Compiler")
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

        "version" {
            println(__version)
        }

        "diag" {
            println(term.bold(term.white("Version: $__version")))
            println(term.bold(term.white("Path: ${os.getenv("DAZE_PATH")}")))
        }

        // "run" {
        //     if os.args.len != 3 {
        //         utils.error("Too few arguments for command `run`.")
        //     }
        //     compile_main(os.args[2], get_base_dir(os.args[2]))?
        //     executable := os.file_name(os.args[2]).replace(".daze", "")
        //     println(os.execute("./${executable}").output)
        // }

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