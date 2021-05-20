%defines "parser.h"

%{
	#include <cmath>
	#include <cstdio>
	#include <iostream>

	extern int yylex();
	extern void yyerror(double* result, const char*);
	using namespace std;
%}

%define api.value.type { double }
%parse-param {double* result}

%token NUM

%left '-' '+'
%left '*' '/'

%start	line;
%%

line: { *result = 0; }	
	| exp YYEOF	{ *result =  $1; }
	; 

exp: NUM				 { $$ = $1; }
	| exp '+' exp  { $$ = $1 + $3; }
	| exp '-' exp  { $$ = $1 - $3; }
	| exp '*' exp  { $$ = $1 * $3; }
	| exp '/' exp  { $$ = $1 / $3; }
	| '(' exp ')'  { $$ = $2; }
	;

%%