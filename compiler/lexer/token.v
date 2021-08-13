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
    dot                // .
    pipe               // |>
    single_quote       // '
    comment            // # comment

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
    kw_unsafe          // `unsafe`
    kw_global          // `global`

    eof                // indicating that there are no more tokens left
}

pub const tokens_map = map{
  "open_paren"         :"(",
  "close_paren"        :")",
  "open_curly"         :"{",
  "close_curly"        :"}",
  "at"                 :"@",
  "semicolon"          :";",
  "comma"              :",",
  "colon"              :":",
  "double_colon"       :"::" ,
  "colon_equal"        :":=",
  "equal"              :"=",
  "double_slash"       :"//",
  "plus"               :"+",
  "plus_plus"          :"++",
  "minus"              :"-",
  "minus_minus"        :"--",
  "div"                :"/",
  "mod"                :"%",
  "and_and"            :"&&",
  "not_equal"          :"!=",
  "equal_equal"        :"==",
  "greater_than"       :">",
  "greater_than_equal" :">=",
  "less_than_equal"    :"<=",
  "less_than"          :"<",
  "not"                :"!",
  "backtick"           :"`",
  "open_square"        :"[",
  "close_square"       :"]",
  "arrow_left"         :"<-",
  "pipe"               :"|>",
  "dot"                :".",
  "single_quote"       :"'",
  // "comment"            :"comment",
}

pub const keywords_map = map{
    "struct": TokenType.kw_struct
    "fn": TokenType.kw_fn
    "is": TokenType.kw_is
    "ret": TokenType.kw_return
    "use": TokenType.kw_use
    "raw": TokenType.kw_raw
    "implement": TokenType.kw_implement
    "if": TokenType.kw_if
    "else": TokenType.kw_else
    "elif": TokenType.kw_elif
    "for": TokenType.kw_for
    "break": TokenType.kw_break
    "in": TokenType.kw_in
    "make": TokenType.kw_make
    "unsafe": TokenType.kw_unsafe
}

pub struct Token {
pub:
    kind TokenType
    value string
    line int
    column int
}