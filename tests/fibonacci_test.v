module tests

fn test_fibonacci() {
    exit_code, output := compile_and_run("fibonacci.daze")
    assert output == "10946"
}