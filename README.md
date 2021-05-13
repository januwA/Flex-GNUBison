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

- yylval: 默认是int, 但是如果在Parser中使用了`%union` 那么yylval也将成为联合类型
- yytext: char*
- yyleng: yytext size

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

## yywrap()

当lex词法分析器到达yyin的结束位置时，将调用yywrap，这样做的目的是，当有另一个输入文件时，yywrap可以调整yyin的值，并通过返回0继续开始词法分析，也可以返回1来完成分析。

可以在".l"文件中使用`%option noyywrap`来要求不使用yywrap函数

## yyin

yyin的值默认为stdin

## yylex()

Lexer 词法分析器, 将文本分析为Tokens

## yyparse()

Parser 语法解析器, 将tokens解析为AST