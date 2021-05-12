%{
#include <stdio.h>
#include <math.h>
%}

%token NUM_INT
%token PLUS MINUS MUL DIV POW
%token NUMINT
%token NEWLINE
%token LP "(" RP ")"

/* 运算符优先级 */
%left PLUS MINUS
%left MUL DIV
%left POW
%left LP
%%

calclist:  %empty
|         calclist expr getValExpr { 
  /* 匹配到左侧的表达式，触发右侧的事件 */ 
  printf("= %d\n", (int)$2); 
}
;

getValExpr:  NEWLINE|YYEOF;

/* $$ 编译为 yyval */
expr:       NUMINT { $$ = $1; }
|           expr PLUS expr    { $$ = $1 + $3; }
|           expr MINUS expr   { $$ = $1 - $3; }
|           expr MUL expr     { $$ = $1 * $3; }
|           expr DIV expr     { $$ = $1 / $3; }
|           expr POW expr     { $$ = pow($1, $3); }
|           LP expr RP        { $$ = $2; }
;
%%