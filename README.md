# Flex & GNU Bison


## flex

1. 生成 lex.yy.c
```
λ win_flex --wincompat ./Lexer.l
```

2. 生成 lex.yy.exe
```
> cl .\lex.yy.c
```

---

## bison

同时生成.h和.c文件
```
λ win_bison -d Parser_3.y
```

编译 lexer
```
λ win_flex --wincompat Lexer_3.l
```

生成exe
```
> cl .\Parser_3.tab.c .\lex.yy.c -o main.exe
> ./main.exe
```


## 清理输出文件
```
λ rm -rf ./*.exe ./*.c ./*.obj ./*.h
```