module utils

import os
import term

pub fn report(filename string, line int, column int, errmsg string, error_type string) {
    file_contents := os.read_file(filename) or { panic("File not found") }
    lines := file_contents.split("\n")
    code := lines[line - 1]
    width, height := term.get_terminal_size()
    line_info := term.bold(term.red("L${line}")) + term.bold(term.red(" | "))
    header := error_type.to_upper()

    println("")
    println("${term.bold(term.red(header))} ${" ".repeat(width - filename.len - header.len - 2)} ${term.bold(filename)}")
    println("")
    println(line_info + term.bold(term.red(code)))
    println("")
    println(errmsg)
}