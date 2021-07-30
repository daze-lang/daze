module lexer

pub enum TokenType {
    open_paren // (
    close_paren // )
    open_curly // {
    close_curly // }
    at // @
    semicolon // ;
    comma // ,
    colon // :
    double_colon // ::
    colon_equal // :=
    slash // /
    double_slash //
    string
    identifier
    number

    // keywords
    kw_struct
    kw_fn
    kw_is
    kw_return
    kw_use

    eof
}

pub struct Token {
pub:
    kind TokenType
    value string
}