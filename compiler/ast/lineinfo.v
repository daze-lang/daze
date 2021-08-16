module ast

struct LineColPair {
mut:
    line int
    column int
}

struct LineInfo {
pub mut:
    from LineColPair
    to LineColPair
}

pub fn new_line_info() LineInfo {
    return LineInfo{LineColPair{0, 0}, LineColPair{0, 0}}
}

pub fn (mut l LineInfo) set_begin(line int, col int) {
    l.from = LineColPair{line, col}
}

pub fn (mut l LineInfo) set_end(line int, col int) {
    l.to = LineColPair{line, col}
}