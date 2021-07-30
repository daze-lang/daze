module ast

pub struct AST {
pub mut:
    name string
    nodes []Statement
}

pub type Statement = FunctionDeclarationStatement
    | ModuleDeclarationStatement

pub type Expr = FunctionCallExpr
    | StringLiteralExpr
    | NoOp

pub type Node = Statement | Expr

pub struct FunctionDeclarationStatement {
pub:
    name string
    body Expr
    return_type string
}

pub struct ModuleDeclarationStatement {
pub:
    name string
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

pub struct NoOp {}