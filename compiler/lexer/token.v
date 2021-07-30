module lexer

pub enum TokenType {
    open_paren      // (
    close_paren     // )
    open_curly      // {
    close_curly     // }
    at              // @
    semicolon       // ;
    comma           // ,
    colon           // :
    double_colon    // ::
    colon_equal     // :=
    equal           // =
    double_slash    //
    string
    identifier
    number
    plus            // +
    minus           // -
    div             // /
    mod             // %
    and_and         // &&
    not_equal       // !=
    equal_equal     // ==
    not             // !
    backtick        // `

    // keywords
    kw_struct
    kw_fn
    kw_is
    kw_return
    kw_use
    kw_raw
    kw_implement

    raw_crystal_code

    eof
}

pub struct Token {
pub:
    kind TokenType
    value string
    line int
    column int
}