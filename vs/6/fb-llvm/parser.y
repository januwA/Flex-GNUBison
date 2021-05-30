%skeleton "lalr1.cc"
%language "c++"
%defines "parser.h"
%define api.token.constructor
%define api.value.type variant
%locations
%parse-param { BaseNode** result }

%code requires {
	#include "BaseNode.h"
}

%code {
	#include <iostream>
	#include "BaseNode.h"
	extern yy::parser::symbol_type yylex();
}

%token DEF "def" EXTERN "extern" IF "if" THEN "then" ELSE "else" FOR "for" IN "in" BINARY "binary" UNARY "unary"
%token<std::string> NUMBER "number" IDENT "ident"
%token PLUS "+" MINUS "-" MUL "*" DIV "/" LPAREN "(" RPAREN ")" COMMA ","
%token LT "<" GT ">"
%token NL ";"

%left "<" ">"
%left "+" "-"
%left "*" "/"


%type<BaseNode*> atom expr stmt protoStmt main
%type<std::vector<BaseNode*>> args
%type<std::vector<std::string>> idList

%start main
%%

main: stmt YYEOF { 
  auto Proto = new PrototypeNode("__main", {});
  $$ = new FunctionNode(Proto, $1);
  *result = $$;
}
;

stmt:	expr { $$ = $1; }
|	"extern" protoStmt { $$ = $2; }
| "def" protoStmt expr	{ $$ = new FunctionNode($<PrototypeNode*>2, $3); }
| "if" expr "then" stmt "else" stmt { $$ = new IfNode($2, $4, $6); }
| "for" IDENT "=" expr "," expr "," expr "in" stmt { $$ = new ForNode($2, $4, $6, $8, $10); }
| "for" IDENT "=" expr "," expr "in" stmt { $$ = new ForNode($2, $4, $6, NULL, $8); }
| ";" {  }
;

protoStmt: IDENT "(" idList ")"	{ $$ = new PrototypeNode(std::move($1), std::move($3)); }
;

idList:	IDENT { $$ = std::vector<std::string>(); $$.push_back($1); }
|	idList "," IDENT { $$ = std::move($1); $$.push_back($3); }
;

expr: atom { $$ = $1; }
| expr "+" expr { $$ = new BinaryNode(token::PLUS, $1, $3); }
| expr "-" expr { $$ = new BinaryNode(token::MINUS, $1, $3); }
| expr "*" expr { $$ = new BinaryNode(token::MUL, $1, $3); }
| expr "/" expr { $$ = new BinaryNode(token::DIV, $1,$3); }
| expr "<" expr { $$ = new BinaryNode(token::LT, $1, $3); }
| expr ">" expr { $$ = new BinaryNode(token::GT, $1, $3); }
;

atom:	NUMBER { $$ = new NumberNode($1); }
|	IDENT	{ $$ = new VariableNode($1); }
|	IDENT "(" args ")"	{ $$ = new CallNode($1, std::move($3)); }
| "(" expr ")" { $$ = $2; }
;

args:	expr { $$ = std::vector<BaseNode*>(); $$.push_back($1); }
| args "," expr { $$ = std::move($1); $$.push_back($3); }
;
%%

void yy::parser::error(const location_type& loc, const std::string& msg)
{
  printf("Parser Error:%s\n%d:%d,%d:%d\n", msg.c_str(), loc.begin.line, loc.begin.column, loc.end.line, loc.end.column);
}