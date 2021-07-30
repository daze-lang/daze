module lexer

const keywords_map = map{
    'struct': TokenType.kw_struct,
    'fn': TokenType.kw_fn,
    'is': TokenType.kw_is,
    'ret': TokenType.kw_return,
    'use': TokenType.kw_use
}

pub fn to_keyword(id string) ?TokenType {
    return keywords_map[id] or {
        return error("Not a keyword.")
    }
}