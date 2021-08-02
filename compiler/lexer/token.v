module lexer

pub enum TokenType {
    open_paren          // (
    close_paren         // )
    open_curly          // {
    close_curly         // }
    at                  // @
    semicolon           // ;
    comma               // ,
    colon               // :
    double_colon        // ::
    colon_equal         // :=
    equal               // =
    double_slash        //
    string
    identifier
    number
    plus                // +
    plus_plus           // ++
    minus               // -
    minus_minus         // --
    div                 // /
    mod                 // %
    and_and             // &&
    _or                 // ||
    not_equal           // !=
    equal_equal         // ==
    greater_than        // >
    greater_than_equal  // >=
    less_than_equal     // <=
    less_than           // <
    not                 // !
    backtick            // `
    open_square         // [
    close_square        // ]
    arrow_left          // <-

    // keywords
    kw_struct
    kw_fn
    kw_is
    kw_return
    kw_use
    kw_raw
    kw_implement
    kw_if
    kw_else
    kw_elif
    kw_for
    kw_break
    kw_in
    kw_make

    raw_crystal_code

    eof
}

pub const tokens_map = map{
  "open_paren":          "(",
  "close_paren":         ")",
  "open_curly":          "{",
  "close_curly":         "}",
  "at":                  "@",
  "semicolon":           ";",
  "comma":               ",",
  "colon":               ":",
  "double_colon":        ":",
  "colon_equal":         "=",
  "equal":               "=",
  "double_slash":        "//",
  "plus":                "+",
  "plus_plus":           "++",
  "minus":               "-",
  "minus_minus":         "--",
  "div":                 "/",
  "mod":                 "%",
  "and_and":             "&&",
  "not_equal":           "!=",
  "equal_equal":         "==",
  "greater_than":        ">",
  "greater_than_equal":  ">=",
  "less_than_equal":     "<=",
  "less_than":           "<",
  "not":                 "!",
  "backtick":            "`",
  "open_square":         "[",
  "close_square":        "]",
  "arrow_left":          "<-",
}

pub struct Token {
pub:
    kind TokenType
    value string
    line int
    column int
}