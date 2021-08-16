module utils

import term

pub fn syntax_error(found string, expected string, line int, column int, filepath string) {
    report(filepath, line, column, "Unexpected: found `${term.underline(found)}`, expected `${term.underline(expected)}`.", "syntax error")
    exit(1)
}

pub fn parser_error(message string, filepath string, line int, column int) {
    msg := term.bold(term.white(message))
    report(filepath, line, column, msg, "parser error")
    exit(1)
}

pub fn codegen_error(message string) {
    msg := term.bold(term.white(message))
    println("${term.bold(term.red("CODEGEN ERROR: "))}$msg")
    exit(1)
}

pub fn error(message string) {
    msg := term.bold(term.white(message))
    println("${term.bold(term.red("ERROR: "))}$msg")
    exit(1)
}
