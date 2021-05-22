%skeleton "lalr1.cc"
%language "c++"
%defines "parser.h"

/* yy_math::parser to yy_math::Parser */
%define api.parser.class {Parser}

/* 生成make_TOKEN 系列的函数 */
%define api.token.constructor

/* 使用c++类, %type<double> expr */
%define api.value.type variant

/* 生成处理位置的代码 */
%locations

/* 重定义namespace名 */
%define api.prefix {yy_math}

%parse-param {FBContext* ctx}

%code requires {
#include "FBContext.h"
}
%code {
extern yy_math::Parser::symbol_type yylex ();
}

%token <double> NUM "number"
%token ADD "+" SUB "-" MUL "*" DIV "/"

%left "+" "-"
%left "*" "/"

%type<double> expr start
%%

start: expr YYEOF { $$ = $1; ctx->result = $1; }
;

expr: NUM  { $$ = $1; printf("col(%d)\n", @1.begin.column); }
|     expr "+" expr { $$ = $1 + $3; }
|     expr "-" expr { $$ = $1 - $3; }
|     expr "*" expr { $$ = $1 * $3; }
|     expr "/" expr { $$ = $1 / $3; }
;

%%

void yy_math::Parser::error(const location_type& loc, const std::string& msg)
{
  printf("Parse Error:%s\n", msg.c_str());
}
