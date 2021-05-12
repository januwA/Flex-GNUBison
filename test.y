// 编译为c++而不是c
%skeleton "lalr1.cc"
%define api.parser.class {test_parser}
%define api.token.constructor
%define api.value.type variant
%define parse.assert
%define parse.error verbose
%locations

%code requires
{
#include <iostream>
#include <map>
#include <list>
#include <vector>
#include <string>
#include <algorithm>


#define ENUM_IDENTIFIERS(o) \
        o(undefined)                              /* undefined */ \
        o(function)                               /* 指向给定函数的指针 */ \
        o(parameter)                              /* 功能参数之一 */ \
        o(variable)                               /* 局部变量 */
#define o(n) n,
enum class id_type {  ENUM_IDENTIFIERS(o) };
#undef o

struct identifier
{
    id_type type  = id_type::undefined;
    std::size_t     index = 0; // function#, parameter# within surrounding function, variable#
    std::string     name;
};

typedef std::list<struct expression> expr_vec;
struct expression
{
    ex_type type;
    identifier      ident{};    // For ident
    std::string     strvalue{}; // For string
    long            numvalue=0; // For number
    expr_vec        params;
    // For while() and if(), the first item is the condition and the rest are the contingent code
    // For fcall, the first parameter is the variable to use as function

    template<typename... T>
    expression(ex_type t, T&&... args) : type(t), params{ std::forward<T>(args)... } {}

    expression()                    : type(ex_type::nop) {}
    expression(const identifier& i) : type(ex_type::ident),  ident(i)            { }
    expression(identifier&& i)      : type(ex_type::ident),  ident(std::move(i)) { }
    expression(std::string&& s)     : type(ex_type::string), strvalue(std::move(s)) { }
    expression(long v)              : type(ex_type::number), numvalue(v) {}

    bool is_pure() const;

    expression operator%=(expression&& b) && { return expression(ex_type::copy, std::move(b), std::move(*this)); }
};

}


// <token> <别名>?  定义别名可以使用别名引用token
// https://www.gnu.org/software/bison/manual/html_node/Token-Decl.html

%token      END 0
%token      IDENTIFIER NUMCONST STRINGCONST
%token             
    RETURN "return" 
    WHILE "while" 
    IF "if" 
    VAR "var" 
%token             
    OR "||"  
    AND "&&"  
    EQ "=="  
    NE "!="  
    PP "++"  
    MM "--"  
    PL_EQ "+="  
    MI_EQ "-="

// 定义运算符优先级,每行都是新的优先级，优先级低的在顶部，优先级高的在底部
// 每种符号只能被定义一次
// https://www.gnu.org/software/bison/manual/html_node/Precedence-Decl.html

%left ','
%right '?' ':' '=' PL_EQ MI_EQ
%left OR AND
%left EQ NE
%left '+' '-'
%left '*'
%right '&' PP MM
%left '(' '['
%%

library:      functions;

// 0 or more
functions:    functions IDENTIFIER paramdecls ':' stmt
|             %empty
;

// 0 or 1
paramdecls:   paramdecl | %empty;

// 1 or more
paramdecl:    paramdecl ',' IDENTIFIER
|             IDENTIFIER
;

stmt:         com_stmt '}'
|             IF '(' var_def1 '}' stmt
|             WHILE '(' var_def1 '}' stmt
|             RETURN expr ';'
|             exprs ';'
|             ';'
;


com_stmt:      '{'
|              com_stmt  stmt
;

var_defs:     VAR   var_def1
|             var_defs ',' var_def1
;


var_def1:     IDENTIFIER  '=' expr
|             IDENTIFIER
;

exprs:        var_defs
|             c_expr1
;

c_expr1:      var_def1
|             var_def1 ',' expr
;

expr:         NUMCONST
|             STRINGCONST
|             IDENTIFIER
|             '(' expr ')'
|             expr '[' c_expr1 ']'
|             expr '(' ')'
|             expr '(' c_expr1 ')'
|             expr '=' expr
|             expr '+' expr
|             expr '-' expr
|             expr PL_EQ expr
|             expr MI_EQ expr
|             expr OR expr
|             expr AND expr
|             expr EQ expr
|             expr NE expr
|             expr ',' expr

 /* 
 *  %prec 上下文相关的优先级
 * https://www.gnu.org/software/bison/manual/html_node/Contextual-Precedence.html 
 */

|             '&' expr
|             '*' expr  %prec '&' 
|             '-' expr  %prec '&'
|             '!' expr  %prec '&'
|             PP expr
|             MM expr   %prec PP
|             expr PP
|             expr MM   %prec PP
|             expr '?' expr ':' expr
;
%%