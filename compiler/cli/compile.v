module cli

import lexer
import parser
import codegen
import checker
import utils
import ast{CompilationResult, Module}
import os

fn module_not_found(name string, path string) {
    println("Module `$name` not found. Aborting.")
}

fn load_modules(mod Module, base string) []Module {
    matches := utils.match_all(mod.code, "use (.*?\n)")
    mut modules := []Module{}
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
        new_mod := Module{
            name: mod_name.join("::"),
            path: module_path + ".daze"
            code: module_file
        }
        modules << new_mod
        modules << load_modules(new_mod, base)
    }

    return modules
}

fn compile_modules(mods []Module, base string) map[string]CompilationResult {
    mut compiled_modules_map := map[string]CompilationResult{}

    for rawmod in mods {
        compiled_modules_map[rawmod.name] = compile(rawmod, base)
    }

    return compiled_modules_map
}

fn replace_imports(code string, lookup map[string]CompilationResult) string {
    mut ret_code := code
    matches := utils.match_all(code, "// MODULE (.*?);")

    for m in matches {
        mod_name := m.replace("// MODULE ", "").replace(";", "")
        println(m)
        ret_code = ret_code.replace(m, lookup[mod_name].code)
        return replace_imports(ret_code, lookup)
    }

    return ret_code
}

pub fn compile(mod Module, base string) CompilationResult {
    mut lexer := lexer.new(mod.code)
    tokens := lexer.lex()
    mut parser := parser.new(tokens, mod.path)
    ast := parser.parse()

    mut codegen := codegen.new_cpp(ast)
    mut code := codegen.run()

    if mod.name == "main" {
        // panic(ast)
        module_lookup := compile_modules(load_modules(mod, base), base)
        mut checker := checker.new(ast, module_lookup)
        checker.run()

        return CompilationResult{
            ast: ast,
            mod: mod,
            code: replace_imports(code, module_lookup)
        }
    }

    return CompilationResult{
        ast: ast,
        mod: mod,
        code: code
    }
}