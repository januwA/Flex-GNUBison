%option noyywrap noline

%{
#include <iostream>
#include "parser.h"

#define YY_DECL yy::parser::symbol_type yylex ()
yy::location loc;
#define yyterminate() return yy::parser::make_YYEOF(loc)
#define _T(t) return yy::parser::make_##t(loc)
#define _ST(t) return yy::parser::make_##t(std::string(yytext, yyleng), loc)

#define YY_USER_ACTION \
    loc.step();     \
    loc.columns(yyleng);


%}

/* https://stackoverflow.com/questions/9611682/flexlexer-support-for-unicode */
ASC     [\x00-\x7f]
ASCN    [\x00-\t\v-\x7f]
U       [\x80-\xbf]
U2      [\xc2-\xdf]
U3      [\xe0-\xef]
U4      [\xf0-\xf4]

UANY    {ASC}|{U2}{U}|{U3}{U}{U}|{U4}{U}{U}{U}
UANYN   {ASCN}|{U2}{U}|{U3}{U}{U}|{U4}{U}{U}{U} 
UONLY   {U2}{U}|{U3}{U}{U}|{U4}{U}{U}{U}

DEC	    [0-9]*(\.[0-9]+)?
IDENT   (?xi:[a-z_][a-z0-9_]*)

%%

[ \t\r\n]   {  }
"#"[^\n]* { /* eat comment */ }
"+" { _T(PLUS);}
"-" { _T(MINUS);}
"*" { _T(MUL);}
"/" { _T(DIV);}
"(" { _T(LPAREN);}
")" { _T(RPAREN);}
"," { _T(COMMA);}
"<" { _T(LT);}
">" { _T(GT);}
";" { _T(NL);}

"def" { _T(DEF); }
"extern" { _T(EXTERN); }
"if" { _T(IF); }
"then" { _T(THEN); }
"else" { _T(ELSE); }
"for" { _T(FOR); }
"in" { _T(IN); }
"binary" { _T(BINARY); }
"unary" { _T(UNARY); }

{DEC} { _ST(NUMBER); }
{IDENT} { _ST(IDENT); }

.				{ printf("Char Error:%s\n%d:%d,%d:%d\n", yytext, loc.begin.line, loc.begin.column, loc.end.line, loc.end.column ); }

%%