module main

pub struct AST {
    pub mut:
        name string
        nodes []Node
}

pub type NodeValue = Node | string

pub enum NodeType {
    top_level
    fn_call
}

pub struct Node {
    pub:
        kind NodeType
        value NodeValue
}