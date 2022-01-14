.namespace ["io"]
  .sub "greet"
    .return ("Hello, World!")
  .end

.namespace ["range"]
  .sub "between"
    .return (10)
  .end


.namespace [ ]
  .sub 'main' :main
    $P0 = get_namespace ["io"]
    $P1 = $P0.'find_var' ("greet")
    $S1 = $P1()
    say $S1

    $P0 = get_namespace ["range"]
    $P1 = $P0.'find_var' ("between")
    $I1 = $P1()
    say $I1
  .end