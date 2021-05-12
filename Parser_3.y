%{
#include <stdio.h>
%}

%token NUM_INT
%token PLUS MINUS MUL DIV
%token NUMINT
%token NEWLINE
%token LP "(" RP ")"
%%

calclist:  %empty
|         calclist expr NEWLINE { 
  /* 匹配到左侧的表达式，触发右侧的事件 */ 
  printf("= %d\n", $2); 
}
;

/* $$ 编译为 yyval */
expr:      factor { $$ = $1; }
|         expr PLUS factor   { $$ = $1 + $3; }
|         expr MINUS factor   { $$ = $1 - $3; }
;


factor:     term { $$ = $1; }
|           factor MUL term { $$ = $1 * $3; }
|           factor DIV term { $$ = $1 / $3; }
;

term:       NUMINT { $$ = $1; }
|           LP expr RP { $$ = $2; }
;
%%