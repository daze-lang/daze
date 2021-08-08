module codegen

struct FileBuffer {
    path string
mut:
    lines []string
}

pub fn (mut buf FileBuffer) writeln(line string) {
    buf.lines << line + "\n"
}