module utils

import ast

pub fn get_raw_type(arg ast.Expr) string {
    return match arg {
        ast.StringLiteralExpr,
        ast.NumberLiteralExpr { arg.value_type }
        else { "" }
    }
}