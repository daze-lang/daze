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
    | RawCrystalCodeExpr
    | StringLiteralExpr
    | NumberLiteralExpr
    | ArrayDefinition
    | RawBinaryOpExpr
    | ForInLoopExpr
    | ArrayPushExpr
    | IncrementExpr
    | DecrementExpr
    | IndexingExpr
    | VariableExpr
    | VariableDecl
    | ForLoopExpr
    | GroupedExpr
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
pub struct RawCrystalCodeExpr {
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
    value []Expr
}

pub struct IfExpression {
pub:
    conditional Expr
    body []Expr
    elseifs []IfExpression
    else_branch []Expr
mut:
    assign_to string
}

pub struct VariableDecl {
pub:
    name string
    value []Expr
    type_name string
}

pub struct FunctionCallExpr {
pub:
    name string
    args []Expr
}

pub struct RawBinaryOpExpr {
pub mut:
    value string
}

pub struct GroupedExpr {
pub:
    body []Expr
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

pub struct IncrementExpr {
pub:
    target string
}

pub struct DecrementExpr {
pub:
    target string
}

pub struct VariableExpr {
pub:
    value string
}

pub struct IndexingExpr {
pub:
    var string
    body Expr
}

pub struct ForLoopExpr {
pub:
    conditional Expr
    body []Expr
}

pub struct ForInLoopExpr {
pub:
    container string
    target string
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