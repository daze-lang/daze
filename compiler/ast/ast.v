module ast

pub struct AST {
pub mut:
    name string
    nodes []Statement
}

pub type Statement = FunctionDeclarationStatement
    | ModuleDeclarationStatement
    | StructDeclarationStatement
    | ModuleUseStatement
    | FunctionArgument
    | UnsafeBlock
    | GlobalDecl
    | Comment
    | NoOp

pub type Expr = FunctionCallExpr
    | StructInitialization
    | OptionalFunctionCall
    | VariableAssignment
    | StringLiteralExpr
    | NumberLiteralExpr
    | ArrayDefinition
    | CharLiteralExpr
    | RawBinaryOpExpr
    | ForInLoopExpr
    | ArrayPushExpr
    | IncrementExpr
    | DecrementExpr
    | IndexingExpr
    | VariableExpr
    | VariableDecl
    | IfExpression
    | ForLoopExpr
    | GroupedExpr
    | UnsafeBlock
    | ReturnExpr
    | ArrayInit
    | BinaryOp
    | Comment
    | NoOp

pub type Node = Statement | Expr

pub struct FunctionDeclarationStatement {
pub mut:
    name string
    args []FunctionArgument
    body []Expr
    return_type string
    gen_type string
}

pub struct UnsafeBlock {
pub:
    body string
}

pub struct StructInitialization {
pub:
    name string
    args []Expr
}

pub struct GlobalDecl {
pub:
    name string
    value string
}

pub struct ModuleDeclarationStatement {
pub:
    name string
}

pub struct RawCrystalCodeExpr {
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
    gen_type string
pub mut:
    member_fns []FunctionDeclarationStatement
}

pub struct ReturnExpr {
pub:
    value []Expr
}

pub struct OptionalFunctionCall {
pub:
    fn_call Expr
    default Expr
}

pub struct IfExpression {
pub:
    conditional []Expr
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

pub struct VariableAssignment {
pub:
    name string
    value []Expr
}

pub struct FunctionCallExpr {
pub:
    name string
    callchain []string
    args []Expr
}

pub struct RawBinaryOpExpr {
pub mut:
    value string
}

pub struct Comment {
pub mut:
    value string
}

pub struct GroupedExpr {
pub:
    body []Expr
}

pub struct ArrayInit {
pub:
    body []Expr
}

pub struct StringLiteralExpr {
pub:
    value string
    value_type string
}

pub struct CharLiteralExpr {
pub:
    value string
    value_type string
}

pub struct NumberLiteralExpr {
pub:
    value f64
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

pub struct BinaryOp {
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
    conditional []Expr
    body []Expr
}

pub struct ForInLoopExpr {
pub:
    container string
    target Expr
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