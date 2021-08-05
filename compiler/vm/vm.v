module main

type Operand = string | int | f64

enum Kind {
    push
    plus
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

fn (mut vm VM) exec(inst Instruction) {
    match inst.kind {
        .push {
            vm.stack << inst.op
            vm.ip++
        }
        .plus {
            right := vm.pop()
            left := vm.pop()

            if mut left is int && mut right is int {
                vm.stack << left + right
            } else if left is f64 && mut right is f64 {
                vm.stack << left + right
            } else if left is string && mut right is string {
                vm.stack << left + right
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
        kind: .plus,
        op: ""
    })

    println(vm)
}