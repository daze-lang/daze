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
    string
    identifier
    number

    // keywords
    kw_struct
    kw_fn
    kw_is

    eof
}

pub struct Token {
pub:
    kind TokenType
    value string
}