module main

import os

pub fn compile_and_run(file_path string) (int, string) {
    result := os.execute("daze build $file_path && ./${file_path.replace(".daze", "")}")
    output := result.output.trim_space()
    os.rm(file_path.replace(".daze", "")) or { panic("Couldn't remove test file. ($file_path)") }
    return result.exit_code, output
}