module utils

import os
import term

pub fn report(filename string, line int, column int, errmsg string, error_type string) {
    file_contents := os.read_file(filename) or { panic("File not found") }
    lines := file_contents.split("\n")
    code := lines[line - 1]
    padding := 8

    print(term.white(term.bold("$filename:$line:$column: ")))
    println("${term.red(term.bold("error: "))}${term.white(term.bold(errmsg))}")
    println(" ".repeat(padding) + code)
    println(" ".repeat(column - 1 + padding) + term.red(term.bold("^")))
}