module ast

pub struct AST {
pub mut:
    name string
    nodes []Statement
}

// TODO (mark): Ditch Statements & Exprs for `Node`

pub type Statement = FunctionDeclarationStatement
    | ModuleDeclarationStatement
    | StructDeclarationStatement
    | RawCrystalCodeStatement
    | ImplementBlockStatement
    | ModuleUseStatement
    | FunctionArgument
    | NoOp

pub type Expr = FunctionCallExpr
    | StringLiteralExpr
    | NumberLiteralExpr
    | ArrayDefinition
    | RawBinaryOpExpr
    | ArrayPushExpr
    | VariableExpr
    | VariableDecl
    | ForLoopExpr
    | ReturnExpr
    | NoOp
    | IfExpression

pub type Node = Statement | Expr

pub struct FunctionDeclarationStatement {
pub mut:
    name string
    args []FunctionArgument
    body []Expr
    return_type string
    is_struct bool
}

pub struct ModuleDeclarationStatement {
pub:
    name string
}

pub struct RawCrystalCodeStatement {
pub:
    value string
}

pub struct ImplementBlockStatement {
pub:
    name string
    fns []FunctionDeclarationStatement
}

pub struct ModuleUseStatement {
pub:
    path string
}

pub struct StructDeclarationStatement {
pub:
    name string
    fields []FunctionArgument
pub mut:
    fns []FunctionDeclarationStatement
}

pub struct ReturnExpr {
pub:
    value Expr
}

pub struct IfExpression {
pub:
    conditional Expr
    body []Expr
    elseifs []IfExpression
    else_branch []Expr
}

pub struct VariableDecl {
pub:
    name string
    value Expr
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
    value_type string
}

pub struct NumberLiteralExpr {
pub:
    value int
    value_type string
}


pub struct VariableExpr {
pub:
    value string
}

pub struct ForLoopExpr {
pub:
    conditional Expr
    body []Expr
}

pub struct ArrayPushExpr {
pub:
    target string
    value Expr
}

pub struct ArrayDefinition {
pub:
    type_name string
    items []Expr
}

pub struct FunctionArgument {
pub:
    name string
    type_name string
}

pub struct NoOp {}