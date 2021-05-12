
/* 不要 yywrap 函数 */
%option noyywrap

%{
int charCount = 0;
int numberCount = 0;
%}


%%
[0-9]+  { numberCount++; charCount++; }
.       { charCount++; }
%%

main()
{
  int tok;
  while(tok = yylex()) 
  {

  }
}