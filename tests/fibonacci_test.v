module main

fn test_fibonacci() {
    exit_code, output := compile_and_run("./fibonacci.daze")
    assert exit_code == 0
    assert output == "10946"
}