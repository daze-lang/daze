module utils

import pcre
import os

pub fn match_all(text string, regexp string) []string {
    mut matches := []string{}
    mut str_copy := text

    mut re := pcre.new_regex(regexp, 0) or { panic(err) }

    for {
        m := re.match_str(str_copy, 0, 0) or { break }
        matched := m.get(0) or { break }
        str_copy = str_copy.replace_once(matched, '')
        matches << matched
    }

    return matches
}

pub fn get_base_dir(path string) string {
    parts := path.split("/")
    parts.pop()
    base := os.join_path(os.getwd(), parts.join("/")) + "/"
    return base
}