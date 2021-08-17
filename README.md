## Known Bugs

- [ ] Circular module import causes crash
- [ ] floats are not handled properly (they are converted to `floatint`)

```nim
# this one fails
sum :: []Int := {};
sum <- hello() + 1;

# this one works as its a grouped expression
sum :: []Int := {};
sum <- (hello() + 1);
```

## TODO

- [ ] AST -> JSON
- [ ] Compile-time type checker
- [ ] Proper error messages for parser errors (marked with TODOs)
- [ ] Implement `when`
- [x] Implement optional return types
- [ ] Implement Sum types
- [ ] Implement Enums
- [ ] Implement maps
- [ ] range (0..9, 0..500)
- [x] Implement module system

## Built in Types

- [x] String
- [x] Char
- [x] Int
- [x] Bool
- [ ] Float
