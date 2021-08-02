module utils

import term

pub fn syntax_error(found string, expected string, line int, column int) {
    err_msg := term.bold(term.white("Unexpected: found `${found}`, expected `${expected}`."))
    line_info := term.bold(term.yellow("(line ${line}, col $column)"))
    println("${term.bold(term.red("ERROR: $err_msg $line_info"))}")
    exit(1)
}

pub fn error(message string) {
    msg := term.bold(term.white(message))
    println("${term.bold(term.red("ERROR: "))}$msg")
    exit(1)
}
