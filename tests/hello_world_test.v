module tests

fn test_hello_world() {
    exit_code, output := compile_and_run("hello_world.daze")
    assert output == "Hello, world!"
}