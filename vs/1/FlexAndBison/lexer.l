%option noyywrap noline
%{
#include "parser.h"
%}

%%

"+"   {return ADD;}
"-"   {return SUB;}
"*"   {return MUL;}
"/"   {return DIV;}
";"   {return EOL;}
[0-9]+(\.[0-9]+)?  { yylval = atof(yytext); return NUMBER;}
[ \t\n]			{ /* empty */ }
.				{  }

%%
