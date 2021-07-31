module main

import os
import pcre

import lexer{Token}
import ast{StructDeclarationStatement}
import parser
import codegen

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
        }
        mut module_file := os.read_file("${module_path}.daze") or { panic("File not found") }
        compiled_modules << load_imports(module_file)?
        compiled_modules << to_crystal(module_file)?
    }

    return compiled_modules
}

fn to_crystal(source string) ?string {
    mut lexer := lexer.Lexer{input: source.split('')}
    tokens := lexer.lex()?
    mut parser := parser.Parser{tokens, -1, Token{}, Token{}, map[string]StructDeclarationStatement{}}
    ast := parser.parse()
    mut codegen := codegen.CodeGenerator{ast, "", []string{}}
    mut code := codegen.run()
    return code
}

fn compile(code string) {
    os.write_file("/tmp/lang.cr", code) or { panic("Failed writing file") }
    os.execute("crystal tool format /tmp/lang.cr")
    println(os.execute("crystal build /tmp/lang.cr").output)
    println("==========================================")
}

fn main() {
    mut input_file := os.read_file("demo/lang.daze") or { panic("File not found") }
    compiled_modules := load_imports(input_file)?
    code := to_crystal(input_file)?

    mut final_code := ""
    for mod in compiled_modules {
        final_code += "$mod\n\n"
    }

    mut builtin_file := os.read_file("compiler/builtins/string.cr") or { panic("File not found") }
    compile(builtin_file + "\n" + final_code + code)
}