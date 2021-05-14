%option noyywrap c++ nounistd

%{
  #include "parser.hh"
%}

%%

"hello"   { return yy::parser::token::HELLO; }
.         { printf("other"); }

%%