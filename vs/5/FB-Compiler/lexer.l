%option noyywrap noline yylineno
%option prefix="yy_math"

%{
#include <iostream>
#include "parser.h"


#define YY_DECL yy_math::Parser::symbol_type yylex ()

yy_math::location loc;
#define yyterminate() return yy_math::Parser::make_YY_MATHEOF(loc)
#define YY_USER_ACTION \
    loc.step();     \
    loc.columns(yyleng);

%}
%%

"+"     {return yy_math::Parser::make_ADD(loc);}
"-"     {return yy_math::Parser::make_SUB(loc);}
"*"     {return yy_math::Parser::make_MUL(loc);}
"/"     {return yy_math::Parser::make_DIV(loc);}
[0-9]+  {return yy_math::Parser::make_NUM(std::stod(yytext), loc); }
. { }

%%