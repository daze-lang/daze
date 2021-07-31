## Known Bugs

```v
fn is_name(p :: Person) :: Bool {
  // This here fails
  if p.name() == "Name" {
    ret true;
  }

  ret false;
}
```
