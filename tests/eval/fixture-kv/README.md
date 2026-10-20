# kv

Reads a file of `key=value` lines (blank lines and `#` comments are ignored).

```
go run . config.txt          # print every key=value
go run . config.txt name     # print the value of name
go run . --keys config.txt   # print only the keys, sorted
```

A missing file prints an error and exits 1.
