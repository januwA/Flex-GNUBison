%option noyywrap yylineno case-insensitive

%{
void yyerror(const char *const _Format, ...);

#include "Parser_6.tab.h"
#include <stdlib.h>
#include <stdarg.h>
%}

num    [0-9]+(\.[0-9]+)?
ident  [a-z_]+
hexNum (?i:0x[a-f0-9]+)

%%
"+"             { return PLUS; }
"-"             { return MINUS; }
"*"             { return MUL; }
"/"             { return DIV; }
"="             { return EQ; }
"**"            { return POW; }
"func"          { return FUNC; }
{num}           { yylval.num = atof(yytext); return NUM; }
{ident}         { yylval.str = yytext; return IDENTIFIER; }
"("             { return LP; }
")"             { return RP; }
{hexNum}        { yylval.num = (double)strtol(yytext, NULL, 16); return NUM; }
[ \r\n]         {  }
.               { yyerror("char error: %c", *yytext); }
%%

void yyerror(const char *const _Format, ...)
{
	va_list ap;
  va_start(ap, _Format);

  fprintf(stderr, "line: %d, ", yylineno);
	vfprintf(stderr, _Format, ap);
	fprintf(stderr, "\n");
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