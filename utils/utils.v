module utils

import regex
import os

pub fn match_all(text string, regexp string) []string {
    mut re := regex.regex_opt(regexp) or { panic(err) }
    return re.find_all_str(text)
}

pub fn get_base_dir(path string) string {
    mut parts := path.split("/")
    parts.pop()
    base := os.join_path(os.getwd(), parts.join("/")) + "/"
    return base
}