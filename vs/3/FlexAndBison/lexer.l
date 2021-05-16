%option noyywrap noline
%{
#include "parser.h"
#define SAVE_STR yylval.val = new std::string(yytext, yyleng)
#define _T(t) return t
%}

%%

"+"   {_T(ADD);}
"-"   {_T(SUB);}
"*"   {_T(MUL);}
"/"   {_T(DIV);}
";"   {_T(EOL);}
"("   {_T(LPAREN);}
")"   {_T(RPAREN);}
"="   {_T(EQ);}
[A-z]+             { SAVE_STR; _T( IDENT); }
[0-9]+(\.[0-9]+)?  { SAVE_STR; _T( NUMBER); }
[ \n\t] { }
.				{  }

%%
