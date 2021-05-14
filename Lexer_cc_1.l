%option noyywrap c++ nounistd

%{
int charCount = 0;
int numberCount = 0;
%}


%%
[0-9]+     { numberCount++; charCount += YYLeng(); }
[a-zA_Z_]+ { charCount += YYLeng(); }
.          { charCount++; }
%%

int main()
{
  FlexLexer* lexer = new yyFlexLexer;
  lexer->yylex();

  printf("%d, %d", numberCount, charCount);
}