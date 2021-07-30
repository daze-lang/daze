module ast

pub struct AST {
pub mut:
    name string
    nodes []Statement
}

pub type Statement = FunctionDeclarationStatement
    | ModuleDeclarationStatement
    | FunctionArgument
    | StructDeclarationStatement

pub type Expr = FunctionCallExpr
    | StringLiteralExpr
    | VariableExpr
    | ReturnExpr
    | NoOp

pub type Node = Statement | Expr

pub struct FunctionDeclarationStatement {
pub:
    name string
    args []FunctionArgument
    body []Expr
    return_type string
}

pub struct ModuleDeclarationStatement {
pub:
    name string
}

pub struct StructDeclarationStatement {
pub:
    name string
    fields []FunctionArgument
}

pub struct ReturnExpr {
pub:
    value Expr
}

pub struct FunctionCallExpr {
pub:
    name string
    args Expr
}

pub struct StringLiteralExpr {
pub:
    value string
}

pub struct VariableExpr {
pub:
    value string
}

pub struct FunctionArgument {
pub:
    name string
    type_name string
}

pub struct NoOp {}