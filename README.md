## Known Bugs

- [ ] Function overrides cause the module system to only pick up the last function with the same name
- [ ] Circular module import causes crash
- [ ] floats are not handled properly (they are converted to `floatint`)

## TODO

- [ ] AST -> JSON
- [ ] Compile-time type checker
  - [ ] Check return types, function argument types, return exprs
- [ ] Proper error messages for parser errors (marked with TODOs)
- [ ] Implement `when`
- [x] Implement optional return types
- [ ] Implement Sum types
- [x] Implement Enums
- [x] Implement maps
- [x] Implement module system
- [ ] Better string interpolation
- [ ] Detect variable shadowing
- [x] Can we make semicolons optional? (or remove them completely for the most part?)
- [ ] Compile time ifs
- [ ] Implement anonymous functions (syntax: ->(var1 :: Type, var2 :: Type) :: ReturnType { return var1 })
- [ ] Custom environment variable shouldn't be required to find the standard library (should be relative to the compiler's binary, which should be symlinked to /usr/bin/)

## Built in Types

- [x] String
- [x] Char
- [x] Int
- [x] Bool
- [ ] Float
