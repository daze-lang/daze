module ast

pub struct AST {
pub mut:
    name string
    nodes []Statement
}

pub type Statement = FunctionDeclarationStatement
    | ModuleDeclarationStatement
    | StructDeclarationStatement
    | EnumDeclarationStatement
    | CompflagStatement
    | ModuleUseStatement
    | FunctionArgument
    | LoadStatement
    | RawCppCode
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
    | BinaryOperation
    | ForInLoopExpr
    | CallChainExpr
    | ArrayPushExpr
    | IncrementExpr
    | DecrementExpr
    | IndexingExpr
    | VariableExpr
    | VariableDecl
    | IfExpression
    | TernaryExpr
    | ForLoopExpr
    | GroupedExpr
    | RawCppCode
    | ReturnExpr
    | ArrayInit
    | BinaryOp
    | TypeCast
    | MapInit
    | Comment
    | NoOp

pub type Node = Statement | Expr

pub struct FunctionDeclarationStatement {
pub mut:
    name string
    args []FunctionArgument
    body []Expr
    return_type string
    external bool
}

pub struct RawCppCode {
pub mut:
    body string
}

pub struct StructInitialization {
pub mut:
    name string
    args []Expr
}

pub struct GlobalDecl {
pub mut:
    name string
    value Expr
}

pub struct ModuleDeclarationStatement {
pub mut:
    name string
}

pub struct ModuleUseStatement {
pub mut:
    path string
}

pub struct StructDeclarationStatement {
pub mut:
    name string
    fields []FunctionArgument
    external bool
    member_fns []FunctionDeclarationStatement
}

pub struct ReturnExpr {
pub mut:
    value Expr
}

pub struct OptionalFunctionCall {
pub mut:
    fn_call Expr
    default Expr
}

pub struct IfExpression {
pub mut:
    conditional Expr
    body []Expr
    elseifs []IfExpression
    else_branch []Expr
    assign_to string
}

pub struct VariableDecl {
pub mut:
    name string
    value Expr
    type_name string
}

pub struct LoadStatement {
pub mut:
    path string
}

pub struct CompflagStatement {
pub mut:
    value string
}

pub struct VariableAssignment {
pub mut:
    name string
    value Expr
}

pub struct FunctionCallExpr {
pub mut:
    name string
    args []Expr
    is_member_fn bool
}

pub struct CallChainExpr {
pub mut:
    chain []Expr
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
pub mut:
    body Expr
}

pub struct ArrayInit {
pub mut:
    body []Expr
}

pub struct MapInit {
pub mut:
    body []MapKeyValuePair
}

pub struct MapKeyValuePair {
pub mut:
    key Expr
    value Expr
}

pub struct StringLiteralExpr {
pub mut:
    value string
    value_type string
}

pub struct CharLiteralExpr {
pub mut:
    value string
    value_type string
}

pub struct NumberLiteralExpr {
pub mut:
    value f64
    value_type string
}

pub struct IncrementExpr {
pub mut:
    target string
}

pub struct DecrementExpr {
pub mut:
    target string
}

pub struct VariableExpr {
pub mut:
    value string
    mod bool
    is_struct_member bool
}

pub struct TernaryExpr {
pub mut:
    conditional Expr
    truthy Expr
    falsey Expr
}

pub struct BinaryOp {
pub mut:
    value string
}

pub struct IndexingExpr {
pub mut:
    var string
    body Expr
}

pub struct ForLoopExpr {
pub mut:
    conditional Expr
    body []Expr
}

pub struct ForInLoopExpr {
pub mut:
    container string
    target Expr
    body []Expr
}

pub struct ArrayPushExpr {
pub mut:
    target string
    value Expr
}

pub struct ArrayDefinition {
pub mut:
    type_name string
    items []Expr
}

pub struct FunctionArgument {
pub mut:
    name string
    type_name string
}

pub struct BinaryOperation {
pub mut:
    lhs Expr
    op string
    rhs Expr
}

pub struct EnumDeclarationStatement {
pub mut:
    name string
    values []string
}

pub struct TypeCast {
pub mut:
    value Expr
    type_name string
}

pub struct NoOp {}