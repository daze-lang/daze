module main

enum TokenType {
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

}

struct Token {
    kind TokenType
    value string
}