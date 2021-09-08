## TODO

- [ ] AST -> JSON
- [ ] Compile-time type checker
  - [ ] Check return types, function argument types, return exprs
- [ ] Proper error messages for parser errors (marked with TODOs)
- [ ] Implement `when`
- [ ] Implement Sum types
- [ ] Better string interpolation
- [ ] Detect variable shadowing
- [ ] Compile time ifs
- [ ] Implement anonymous functions (syntax: ->(var1 :: Type, var2 :: Type) :: ReturnType { return var1 })
- [ ] Custom environment variable shouldn't be required to find the standard library (should be relative to the compiler's binary, which should be symlinked to /usr/bin/)

## DONE

- [x] Implement optional return types
- [x] Implement Enums
- [x] Implement maps
- [x] Implement module system
- [x] Can we make semicolons optional? (or remove them completely for the most part?)
