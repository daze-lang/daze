module main

fn test_hello_world() {
    exit_code, output := compile_and_run("./hello_world.daze")
    assert exit_code == 0
    assert output == "Hello, world!"
}