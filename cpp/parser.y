%language "c++"
%skeleton "lalr1.cc"

%{
  #include <fstream>
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

int main(int argc, char **argv)
{
  std::filebuf fb;
  if (argc >= 2)
  {
    if (fb.open(argv[1], std::ios::in))
    {
      std::istream is(&fb);
      lpLexer = new yyFlexLexer(&is);
    }
    else
    {
      printf("open file %s error.", argv[1]);
    }
  }
  else
  {
    lpLexer = new yyFlexLexer();
  }
  lpParser = new yy::parser();
  lpParser->parse();
  fb.close();
  return 0;
}