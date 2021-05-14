%language "c++"
%skeleton "lalr1.cc"

%{
  #include <FlexLexer.h>
  #include "parser.hh"
  yyFlexLexer* lpLexer;
  yy::parser*  lpParser;
  int yylex(yy::parser::semantic_type* value);
%}

%token HELLO

%%

%start expr;

expr:  HELLO { printf("in: %s\n", lpLexer->YYText()); }
;

%%

int yylex(yy::parser::semantic_type* value)
{
  return lpLexer->yylex();
}

void yy::parser::error (const std::string& msg)
{
  printf("Error: %s", msg.c_str());
}

int main()
{
  lpLexer = new yyFlexLexer();
  lpParser = new yy::parser();
  return lpParser->parse();
}