module lexer

pub enum TokenType {
    open_paren         // (
    close_paren        // )
    open_curly         // {
    close_curly        // }
    at                 // @
    semicolon          // ;
    comma              // ,
    colon              // :
    double_colon       // ::
    colon_equal        // :=
    equal              // =
    double_slash       //
    string             // cstrings
    identifier         // identifiers
    number             // any number
    plus               // +
    plus_plus          // ++
    minus              // -
    minus_minus        // --
    div                // /
    mod                // %
    and_and            // &&
    _or                // ||
    not_equal          // !=
    equal_equal        // ==
    greater_than       // >
    greater_than_equal // >=
    less_than_equal    // <=
    less_than          // <
    not                // !
    backtick           // `
    open_square        // [
    close_square       // ]
    arrow_left         // <-

    kw_struct          // `struct`
    kw_fn              // `fn`
    kw_is              // `is`
    kw_return          // `ret`
    kw_use             // `use`
    kw_raw             // `raw`
    kw_implement       // `implement`
    kw_if              // `if`
    kw_else            // `else`
    kw_elif            // `elif`
    kw_for             // `for`
    kw_break           // `break`
    kw_in              // `in`
    kw_make            // `make`

    raw_crystal_code   // raw crystal code block

    eof                // indicating that there are no more tokens left
}

pub const tokens_map = map{
  "open_paren"         :" (",
  "close_paren"        :" )",
  "open_curly"         :" {",
  "close_curly"        :" }",
  "at"                 :" @",
  "semicolon"          :" ;",
  "comma"              :" ,",
  "colon"              :":" ,
  "double_colon"       :"::" ,
  "colon_equal"        :" =",
  "equal"              :" =",
  "double_slash"       :" //",
  "plus"               :" +",
  "plus_plus"          :" ++",
  "minus"              :" -",
  "minus_minus"        :" --",
  "div"                :" /",
  "mod"                :" %",
  "and_and"            :" &&",
  "not_equal"          :" !=",
  "equal_equal"        :" ==",
  "greater_than"       :" >",
  "greater_than_equal" :" >=",
  "less_than_equal"    :" <=",
  "less_than"          :" <",
  "not"                :" !",
  "backtick"           :" `",
  "open_square"        :" [",
  "close_square"       :" ]",
  "arrow_left"         :" <-",
}

pub struct Token {
pub:
    kind TokenType
    value string
    line int
    column int
}