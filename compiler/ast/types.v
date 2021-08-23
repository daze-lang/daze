module ast

pub struct Module {
pub mut:
    name string
    path string
    code string
}

pub struct CompilationResult {
pub mut:
    ast AST
    mod Module
    code string
}