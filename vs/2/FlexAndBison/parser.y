%defines "parser.h"
%token-table

/* to .h */
%code requires {
#include "Ast.h"
}

/* to .h */
%union {
  Ast* a;
  const char* val;
}

/* to .cc */
%{
#include <iostream>
#include "Eval.hpp"

extern std::string ttToStr(int t);
extern int yylex();
extern void yyerror(const char*);

%}

%token <val> NUMBER "number"
%token ADD "+" SUB "-" MUL "*" DIV "/" EOL ";"


%left ADD SUB
%left MUL DIV

%type <a> expr atom

%%

calclist: %empty
| calclist expr EOL { 
  printf("%s = %lf\n", $2->toString().c_str(), Eval().eval($2));
  delete $2;
}
;

expr: expr ADD expr { $$ = new BinaryAst($1, ADD, $3); }
| expr SUB expr { $$ = new BinaryAst($1, SUB, $3); }
| expr MUL expr { $$ = new BinaryAst($1, MUL, $3); }
| expr DIV expr { $$ = new BinaryAst($1, DIV, $3); }
| atom
;

atom: NUMBER  { $$ = new NumberAst($1); }
;

%%

std::string ttToStr(int t) {
  return std::string(yytname[YYTRANSLATE(t)]);
}