
/* 不要 yywrap 函数 */
%option noyywrap

%{

// token type
enum TT {
  END_OF_FILE,
  PLUS,
  MINUS,
  MUL,
  DIV,
  NUM_INT,
};

int intValue = NULL;
%}


%%
<<EOF>> { return END_OF_FILE; }
"+"     { return PLUS; }
"-"     { return MINUS; }
"*"     { return MUL; }
"/"     { return DIV; }
[0-9]+  { intValue = atoi(yytext); return NUM_INT; }
.       {  }
%%

main()
{
  int tok;
  while(1)
  {
    // yylex() == nextToken()
    // 每次都会返回一个解析的token
    tok = yylex();
    if( tok == NUM_INT ) 
    {
      printf("int: %d\n", intValue);
    }
    if(tok == END_OF_FILE) break;
  }
}