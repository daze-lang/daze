module main

import term
import lexer
import parser
import codegen
import checker
import utils
import ast
import os
import cli

const __version = "0.0.3"

fn module_not_found(name string, path string) {
    println(term.red(term.bold("Module `$name` not found. Aborting.")))
    exit(1)
}

fn has_astyle() bool {
    result := os.execute("astyle --help")
    return result.exit_code == 0
}

fn load_modules(mod ast.Module, base string) []ast.Module {
    matches := utils.match_all(mod.code, "use.*\n$")
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
        if !compiled_modules_map.keys().contains(rawmod.name) {
            compiled_modules_map[rawmod.name] = compile(rawmod, base)
        }
    }

    return compiled_modules_map
}

fn replace_imports(code string, lookup map[string]ast.CompilationResult) string {
    mut ret_code := code
    matches := utils.match_all(code, "// MODULE (.*);")

    for m in matches {
        mod_name := m.replace("// MODULE ", "").replace(";", "")
        ret_code = ret_code.replace(m, lookup[mod_name].code)
        return replace_imports(ret_code, lookup)
    }

    return ret_code
}

pub fn compile(mod ast.Module, base string) ast.CompilationResult {
    module_lookup := compile_modules(load_modules(mod, base), base)

    mut lexer := lexer.new(mod.code)
    tokens := lexer.lex()
    mut parser := parser.new(tokens, mod.path)
    program_ast := parser.parse()

    // mut checker := checker.new(program_ast, module_lookup)
    // transformed_ast := checker.run()

    mut codegen := codegen.new_parrot(program_ast)
    mut code := codegen.run()

    if mod.name == "main" {
        // panic(transformed_ast)
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

fn get_command_args(output_file string, bin_file_name string, include_dir string) []string {
    $if linux {
        return [
            "gcc -x c++ $output_file -o $bin_file_name",
            "-lstdc++",
            "-I$include_dir",
            "-static",
            "-fno-diagnostics-show-caret -fdiagnostics-color=always"
        ]
    } $else $if macos {
        return [
            "g++ $output_file -o $bin_file_name",
            "-I$include_dir",
        ]
    } $else {
        panic("Unsupported platform.")
        return []string{}
    }
}

fn write_generated_output(file_name string, code string) {
    dir := os.temp_dir()
    out_file := "$dir/${file_name}.pir"
    os.write_file(out_file, code) or { panic("Failed writing file") }
    // if has_astyle() {
    //     os.execute("astyle $out_file")
    // }
    // include_dir := "${os.getenv("DAZE_PATH")}/thirdparty"
    // command_args := get_command_args(out_file, file_name, include_dir)
    // result := os.execute(command_args.join(" "))

    // if result.exit_code != 0 {
    //     println(term.red(term.bold("Codegen error. The C++ Compiler failed.")))
    //     println(term.red(term.bold("========================================")))
    //     println("")
    //     // println(result.output)
    // } else {
    //     // os.execute("rm -rf $dir/${file_name}.cpp")
    // }
}

// compiles the main entry point & writes it to file
fn compile_main(path string, base string) ? {
    mut main_module_contents := os.read_file(path) or {
        println(term.red(term.bold("`$path` not found.")))
        exit(1)
    }
    // TODO: not a good way to do things
    // mut header := os.read_file(os.getenv("DAZE_PATH") + "/include/header.h") or {
    //     println(term.red(term.bold("Default header include not found.")))
    //     exit(1)
    // }

    main_module := ast.Module{
        name: "main",
        path: path,
        code: main_module_contents
    }

    result := compile(main_module, base)
    // version_def := "#define __DAZE_VERSION__ ${__version}\n"
    output_file_name := os.file_name(path).replace(".daze", "")
    code := result.code
    write_generated_output(output_file_name, code)
}

fn help() {
    println(term.bold(term.bright_blue("Daze Compiler v${__version}\n")))
    println(term.bold(term.white("Available subcommands:\n")))
    println(" ".repeat(2) + "build <main_file>  Builds an executable")
    println(" ".repeat(2) + "diag               Outputs helpful information about the setup of the Daze Compiler")
    println(" ".repeat(2) + "version            Outputs the version of the installed Daze Compiler")
}

fn main() {
    if os.args.len == 1 {
        help()
        return
    }

    mut app := cli.Command{
        name: "daze"
        description: "Compiler for the Daze Programming Language."
        disable_help: true
        commands: [
            cli.Command{
                name: "build"
                disable_help: true
                execute: fn (cmd cli.Command) ? {
                    if cmd.args.len == 0 {
                        help()
                        return
                    }
                    compile_main(cmd.args[0], utils.get_base_dir(cmd.args[0]))?
                    return
                }
            },
            cli.Command{
                name: "help"
                disable_help: true
                execute: fn (cmd cli.Command) ? {
                    help()
                    return
                }
            },
            cli.Command{
                name: "version"
                disable_help: true
                execute: fn (cmd cli.Command) ? {
                    println(__version)
                    return
                }
            },
            cli.Command{
                name: "diag"
                disable_help: true
                execute: fn (cmd cli.Command) ? {
                    println(cmd.parent)
                    println(term.bold(term.white("Version: $__version")))
                    println(term.bold(term.white("Daze Compiler Path: ${os.getenv("DAZE_PATH")}")))
                    return
                }
            },
        ]
    }
    app.setup()
    app.parse(os.args)
}