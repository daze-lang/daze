module codegen

struct FileBuffer {
    path string
mut:
    lines []string
}

pub fn (mut buf FileBuffer) writeln(line string) {
    buf.lines << line
}

pub fn (mut buf FileBuffer) str() string {
    return buf.lines.join("\n")
}