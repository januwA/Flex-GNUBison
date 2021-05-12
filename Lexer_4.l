/* 支持16进制, 暮运算, 输入文件 */

%{
#include "Parser_4.tab.h"
#include <stdlib.h>
extern int yywrap() { return 1; }
%}


%%
"+"             { return PLUS; }
"-"             { return MINUS; }
"*"             { return MUL; }
"/"             { return DIV; }
"**"            { return POW; }
[0-9]+          { yylval = atoi(yytext); return NUMINT; }
\n              { return NEWLINE; }
"("             { return LP; }
")"             { return RP; }
(?i:0x[a-f0-9]+)      { yylval = strtol(yytext, NULL, 16); return NUMINT; }
.               {  }
%%

yyerror(char* s)
{
  printf("error: %s\n", s);
}

int main(int argc, char** argv)
{

  // 如果输入的文件路径，则打开文件作为输入
  if(argc > 1) 
  {
    if(!(yyin = fopen( argv[1], "r" )))
    {
      printf("open file '%s' error\n",argv[1] );
      return 1;
    }
  }

  yyparse();
  return 0;
}