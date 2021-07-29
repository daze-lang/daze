module main

const keywords_map = map{
    'struct': TokenType.kw_struct,
    'fn': TokenType.kw_fn,
    'is': TokenType.kw_is,
}

pub fn to_keyword(id string) ?TokenType {
    return keywords_map[id] or {
        return error("Not a keyword.")
    }
}