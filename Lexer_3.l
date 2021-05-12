%{
#include "Parser_3.tab.h"
extern int yywrap() { return 1; }
%}


%%
"+"     { return PLUS; }
"-"     { return MINUS; }
"*"     { return MUL; }
"/"     { return DIV; }
[0-9]+  { yylval = atoi(yytext); return NUMINT; }
\n      { return NEWLINE; }
"("      { return LP; }
")"      { return RP; }
.       {  }
%%

yyerror(char* s)
{
  printf("error: %s\n", s);
}

main()
{
  yyparse();
}