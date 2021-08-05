module main

type Operand = string | int | f64

enum Kind {
    push
    add
    sub
    div
    mul
}

struct Instruction {
    kind Kind
    op Operand
}

struct VM {
mut:
    stack []Operand
    ip int
}

fn (mut vm VM) push(op Operand) {
    vm.stack << op
    vm.ip++
}

fn (mut vm VM) exec(inst Instruction) {
    match inst.kind {
        .push {
            vm.push(inst.op)
        }
        .add {
            right := vm.pop()
            left := vm.pop()

            if mut left is int && mut right is int {
                vm.push(left + right)
            } else if left is f64 && mut right is f64 {
                vm.push(left + right)
            } else if left is string && mut right is string {
                vm.push(left + right)
            }
        }
        .sub {
            right := vm.pop()
            left := vm.pop()

            if mut left is int && mut right is int {
                vm.push(left - right)
            } else if left is f64 && mut right is f64 {
                vm.push(left - right)
            } else if left is string && mut right is string {
                vm.push(0)
            }
        }
        .mul {
            right := vm.pop()
            left := vm.pop()

            if mut left is int && mut right is int {
                vm.push(left * right)
            } else if left is f64 && mut right is f64 {
                vm.push(left * right)
            } else if left is string && mut right is string {
                vm.push(0)
            }
        }
        .div {
            right := vm.pop()
            left := vm.pop()

            if mut left is int && mut right is int {
                vm.push(left / right)
            } else if left is f64 && mut right is f64 {
                vm.push(left / right)
            } else if left is string && mut right is string {
                vm.push(0)
            }
        }
    }
}

fn (mut vm VM) pop() Operand {
    op := vm.stack.pop()
    vm.ip--
    return op
}

fn main() {
    mut vm := VM{
        stack: []Operand{},
        ip: 0
    }

    vm.exec(Instruction{
        kind: .push,
        op: 5
    })
    vm.exec(Instruction{
        kind: .push,
        op: 4
    })
    vm.exec(Instruction{
        kind: .add,
        op: ""
    })
    vm.exec(Instruction{
        kind: .push,
        op: 2
    })
    vm.exec(Instruction{
        kind: .mul,
        op: ""
    })

    println(vm)
}