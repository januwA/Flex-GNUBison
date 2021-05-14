## Flex
```
λ win_bflex.exe lexer.l
```

## Bison

生成 'parser.hh' 和 'parser.cc'
```
λ win_bison.exe -d -o parser.cc parser.y
```

```
> cl -I ./ .\parser.cc .\lex.yy.cc -o main.exe
> main.exe
```