%defines "parser.h"

%{
#include <iostream>

extern int yylex();
extern void yyerror(const char*);

%}

%define api.value.type { double }

%token NUMBER "number"
%token ADD "+" SUB "-" MUL "*" DIV "/" EOL ";"

%left ADD SUB
%left MUL DIV

%%
calclist: %empty
| calclist expr EOL { printf("=> %lf\n", $2); }
;

expr: expr ADD expr { $$ = $1 + $3; }
| expr SUB expr { $$ = $1 - $3; }
| expr MUL expr { $$ = $1 * $3; }
| expr DIV expr { $$ = $1 / $3; }
| atom
;

atom: NUMBER
;


%%