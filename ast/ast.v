module ast

pub struct AST {
pub mut:
    name string
    nodes []Statement
}

pub type Statement = FunctionDeclarationStatement
    | ModuleDeclarationStatement
    | StructDeclarationStatement
    | RawCrystalCodeStatement
    | ModuleUseStatement
    | FunctionArgument
    | Comment
    | NoOp

pub type Expr = FunctionCallExpr
    | StringLiteralExpr
    | NumberLiteralExpr
    | RawBinaryOpExpr
    | VariableExpr
    | VariableDecl
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

pub struct RawCrystalCodeStatement {
pub:
    value string
}

pub struct ModuleUseStatement {
pub:
    path string
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

pub struct VariableDecl {
pub:
    name string
    value Expr
}

pub struct Comment {
pub:
    value string
}


pub struct FunctionCallExpr {
pub:
    name string
    args []Expr
}

pub struct RawBinaryOpExpr {
pub:
    value string
}

pub struct StringLiteralExpr {
pub:
    value string
}

pub struct NumberLiteralExpr {
pub:
    value int
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