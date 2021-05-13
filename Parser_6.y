%{
#include <stdio.h>
#include <math.h>

enum AstType { 
  BINARY_AST, NUMBER_AST, ACCESS_AST, ASSIGN_AST,
  CALL_AST, FUN_AST,
 };

struct ast 
{
  int type;

  // binary ast
  struct ast* left;
  int op;
  struct ast* right;

  // number ast
  double value;

  // access ast 使用变量
  char* str;

  // assign ast 分配变量
  // IDENT EQ data
  struct ast* data;

  // call ast
  // name(<params>)
  int paramsSize;
  struct symbol* params;

  // fun ast
  // fun(a,b) => a + b
  struct ast* body;

};

// 构建 ast
struct ast* newBinaryAst(struct ast* left, int op, struct ast* right);
struct ast* newNumberAst(double value);
struct ast* newAccessAst(char* name);
struct ast* newAssignAst(char* name, struct ast* data);
struct ast* newCallAst(struct ast* name, struct symbol* params, int paramsSize);
struct ast* newFunAst(struct symbol* params, int paramsSize, struct ast* body);


// 变量
struct symbol 
{
  char* name;
  struct ast* value;
};
#define MAX_SYMBOLS_SIZE  100
struct context 
{
  struct symbol* symbols[MAX_SYMBOLS_SIZE];
  struct context* parent;
  
};


// 构建 symbol
struct symbol* newSymbol(char* name, struct ast* value);
struct context* newContext(struct symbol* symbols, struct context* parent);


// 解析ast,runtimne
double eval(struct ast*);

// 清理内存
void astfree(struct ast*);
%}

// 声明语法解析器中符号值的类型
// 定义了联合类型，需要告诉bison每种语法符号使用的值类型
%union {
  struct ast* a;
  char* str;
  double num;
}

%token <a> FUNC 
%token <num> NUM 
%token <str> IDENTIFIER
%token PLUS MINUS MUL DIV POW
%token LP "(" RP ")" EQ "="

/* 运算符优先级 */
%left PLUS MINUS
%left MUL DIV
%left POW
%left LP

%type <a> expr stmt
%%

calclist:  %empty
|         calclist stmt YYEOF {
  printf("= %lf\n", eval($2) ); 
  astfree($2);
  }
;

stmt:  IDENTIFIER EQ stmt { $$ = newAssignAst($1, $3); }
| expr       { $$ = $1; }
| IDENTIFIER { $$ = newAccessAst($1); }
;

/* $$ 编译为 yyval */
expr:       NUM               { $$ = newNumberAst($1); }
|           expr PLUS expr    { $$ = newBinaryAst($1, PLUS, $3); }
|           expr MINUS expr   { $$ = newBinaryAst($1, MINUS, $3); }
|           expr MUL expr     { $$ = newBinaryAst($1, MUL, $3); }
|           expr DIV expr     { $$ = newBinaryAst($1, DIV, $3); }
|           expr POW expr     { $$ = newBinaryAst($1, POW, $3); }
|           LP expr RP        { $$ = $2; }
;
%%


struct ast* newBinaryAst(struct ast* left, int op, struct ast* right)
{
  struct ast* a = malloc(sizeof(struct ast));
  if(!a)
  {
    yyerror("newBinaryAst malloc error.");
    exit(0);
  }

  a->type = BINARY_AST;
  a->left = left;
  a->op = op;
  a->right = right;
  return a;
}

struct ast* newNumberAst(double value)
{
  struct ast* a = malloc(sizeof(struct ast));
  if(!a)
  {
    yyerror("newNumberAst malloc error.");
    exit(0);
  }

  a->type = NUMBER_AST;
  a->value = value;
  return a;
}


struct ast *newAccessAst(char* name)
{
  struct ast *a = malloc(sizeof(struct ast));
  if (!a)
  {
    yyerror("newAccessAst malloc error.");
    exit(0);
  }

  a->type = ACCESS_AST;
  a->str = name;
  return a;
}

struct ast *newAssignAst(char* name, struct ast* data)
{
  struct ast *a = malloc(sizeof(struct ast));
  if (!a)
  {
    yyerror("newAssignAst malloc error.");
    exit(0);
  }

  a->type = ASSIGN_AST;
  a->str = name;
  a->data = data;
  return a;
}

struct ast *newCallAst(struct ast* name, struct symbol* params, int paramsSize)
{
  struct ast *a = malloc(sizeof(struct ast));
  if (!a)
  {
    yyerror("newCallAst malloc error.");
    exit(0);
  }

  a->type = CALL_AST;
  a->str = name;
  a->params = params;
  a->paramsSize = paramsSize;
  return a;
}

struct ast *newFunAst(struct symbol* params, int paramsSize, struct ast* body)
{
  struct ast *a = malloc(sizeof(struct ast));
  if (!a)
  {
    yyerror("newCallAst malloc error.");
    exit(0);
  }

  a->type = FUN_AST;
  a->params = params;
  a->paramsSize = paramsSize;
  a->body = body;
  return a;
}

double eval(struct ast *a)
{
  double result;

  switch (a->type)
  {
  case NUMBER_AST:
    result = a->value;
    break;

  case BINARY_AST:
    switch (a->op)
    {
    case PLUS:
      result = eval(a->left) + eval(a->right);
      break;
    case MINUS:
      result = eval(a->left) - eval(a->right);
      break;
    case MUL:
      result = eval(a->left) * eval(a->right);
      break;
    case DIV:
      result = eval(a->left) / eval(a->right);
      break;
    case POW:
      result = pow(eval(a->left), eval(a->right));
      break;
    default:
      yyerror("BINARY_AST error op: %d", a->op);
      break;
    }
    break;

  case ACCESS_AST:
    int has = 0;
    for (size_t i = 0; i < MAX_SYMBOLS_SIZE; i++)
    {
      if(globalSymbols[i].name == a->str)
      {
        has = 1;
        result = eval(globalSymbols[i].value);
        break;
      }
    }
    if(!has) yyerror("symbol is not define: %s", a->str);
    break;
  case ASSIGN_AST:
    /* 变量赋值 */
    registerSymbol(a->str, a->data);
    result = eval(a->data);
    break;
  default:
    yyerror("error ast: %d", a->type);
    break;
  }

  return result;
}

void astfree(struct ast *a)
{
  switch (a->type)
  {
  case BINARY_AST:
    astfree(a->left);
    astfree(a->right);
    break;
  case ASSIGN_AST:
    astfree(a->data);
    break;
  case CALL_AST:
    for (size_t i = 0; i < a->paramsSize; i++)
    {
      astfree(a->params[i].value);
    }
    break;
  case FUN_AST:
    for (size_t i = 0; i < a->paramsSize; i++)
    {
      astfree(a->params[i].value);
    }
    astfree(a->body);
    break;
  default:
    break;
  }
  free(a);
}
