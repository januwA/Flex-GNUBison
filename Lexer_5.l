/*
* case-insensitive: 忽略模式中的大小写匹配
* yylineno: 遇到\n会自动+1，后退一个换行符-1
* nodefault: 取消默认规则，以回显不匹配的文本( 开启了这个.不会匹配到\n，需要换成.|\n )
*/
%option noyywrap nodefault yylineno case-insensitive

%{
#include <stdlib.h>
%}


%%
.|\n               {  }
%%

yyerror(char* s)
{
  printf("error: %s\n", s);
}

int main(int argc, char** argv)
{

  if(argc > 1) 
  {
    if(!(yyin = fopen( argv[1], "r" )))
    {
      printf("open file '%s' error\n",argv[1] );
      return 1;
    }
  }

  yylex();
  printf("line: %d\n", yylineno);
  return 0;
}