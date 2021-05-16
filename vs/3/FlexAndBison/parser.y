%defines "parser.h"
%token-table

/* to .h */
%code requires {
#include "Ast.h"
}

/* to .h */
%union {
  Ast* a;
  std::string* val;
  std::vector<Ast*>* stmts;
}

/* to .cc */
%{
#include <iostream>
#include <map>
#include <vector>
#include "Eval.hpp"

extern std::string ttToStr(int t);
extern int yylex();
extern int yyleng;
extern void yyerror(const char*);

%}

%token <val> NUMBER "number" IDENT "ident"
%token ADD "+" SUB "-" MUL "*" DIV "/" EOL ";" LPAREN "(" RPAREN ")" EQ "="


%left ADD SUB
%left MUL DIV

%type <a>  assignExpr expr atom 
%type <stmts> member

%%


member: %empty  {  }
| assignExpr  { $$ = new std::vector<Ast*>(); $$->push_back($1); /* 第一次触发，之后都会触发下面的表达式 */ }
| member assignExpr  { $$ = $1; $$->push_back($2); }
| member EOL { 
  /* Runtime */

  /* test
   a = b = 1
   a + 3 - b;
   = 3.000000
  */

  MemberAst programAst = MemberAst(*$1);
  std::map<std::string, Ast*> globalContext;

  double result =  Eval().eval(&programAst, &globalContext);
  printf("= %lf\n", result);

  // delete $1; // 如果是文件到YYEOF应该清理所有资源
  $1->clear(); // 清空旧的ast指针
  $$ = $1;
}
;

assignExpr: expr  { $$ = $1; }
| IDENT EQ assignExpr { $$ = new VarAssignAst(*$1, $3); }
;

expr: expr ADD expr { $$ = new BinaryAst($1, ADD, $3); }
| expr SUB expr { $$ = new BinaryAst($1, SUB, $3); }
| expr MUL expr { $$ = new BinaryAst($1, MUL, $3); }
| expr DIV expr { $$ = new BinaryAst($1, DIV, $3); }
| LPAREN expr RPAREN { $$ = $2; }
| atom
;

atom: NUMBER  { $$ = new NumberAst(*$1); }
| IDENT { $$ = new VarAccessAst(*$1); }
;

%%

std::string ttToStr(int t) {
  return std::string(yytname[YYTRANSLATE(t)]);
}