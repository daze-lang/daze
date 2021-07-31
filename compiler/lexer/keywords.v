module lexer

const keywords_map = map{
    "struct": TokenType.kw_struct,
    "fn": TokenType.kw_fn,
    "is": TokenType.kw_is,
    "ret": TokenType.kw_return,
    "use": TokenType.kw_use,
    "raw": TokenType.kw_raw,
    "implement": TokenType.kw_implement,
    "if": TokenType.kw_if
    "else": TokenType.kw_else
    "elif": TokenType.kw_elif
}

pub fn is_keyword(id string) bool {
    return keywords_map.keys().contains(id)
}

pub fn to_keyword(id string) ?TokenType {
    return keywords_map[id] or {
        return error("Not a keyword.")
    }
}