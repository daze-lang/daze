module cli

import lexer
import parser
import codegen
import utils
import os

fn load_modules(mod Module) []Module {
    matches := utils.match_all(mod.code, "use (.*?);")
    mut modules := []Module{}

    for m in matches {
        mut module_path := m.replace("\"", "").replace("use ", "").replace(";", "")
        module_name := module_path.replace("daze::", "")
        if module_path.starts_with("daze::") {
            module_path = "${os.getenv("DAZE_PATH")}/stdlib/$module_name"
        }

        mut module_file := os.read_file("${module_path}.daze") or { panic("File not found") }
        new_mod := Module{
            name: module_name
            path: module_path
            code: module_file
        }
        modules << new_mod
        modules << load_modules(new_mod)
    }

    return modules
}

fn compile_modules(mods []Module) map[string]CompilationResult {
    mut compiled_modules_map := map[string]CompilationResult{}

    for rawmod in mods {
        compiled_modules_map[rawmod.name] = compile(rawmod)
    }

    return compiled_modules_map
}

fn replace_imports(code string, lookup map[string]CompilationResult) string {
    mut ret_code := code
    matches := utils.match_all(code, "// MODULE (.*?);")

    for m in matches {
        mod_name := m.replace("// MODULE ", "").replace(";", "")
        ret_code = ret_code.replace(m, lookup[mod_name].code)
        return replace_imports(ret_code, lookup)
    }

    return ret_code
}

pub fn compile(mod Module) CompilationResult {
    mut lexer := lexer.new(mod.code)
    tokens := lexer.lex()
    mut parser := parser.new(tokens, mod.path)
    ast := parser.parse()
    // panic(ast)

    mut codegen := codegen.new_cpp(ast)
    mut code := codegen.run()

    if mod.name == "main" {
        module_lookup := compile_modules(load_modules(mod))
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