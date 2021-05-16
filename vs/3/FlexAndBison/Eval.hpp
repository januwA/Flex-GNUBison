#pragma once

#include <iostream>
#include <map>
#include <string>
#include "Ast.h"


class Eval
{
public:
  Eval() {};

  double eval(Ast* ast, std::map<std::string, Ast*>* context)
  {
    switch (ast->id())
    {
    case Ast::AstType::NUMBER:
      return reinterpret_cast<NumberAst*>(ast)->value;
    case Ast::AstType::BINARY:
    {
      auto a = reinterpret_cast<BinaryAst*>(ast);
      double left = eval(a->left, context);
      double right = eval(a->right, context);
      int op = a->op;
      switch (op)
      {
      case  yytokentype::ADD:
        return left + right;

      case  yytokentype::SUB:
        return left - right;

      case  yytokentype::MUL:
        return left * right;

      case  yytokentype::DIV:
        return left / right;
      default:
        printf("Eval Error: error op %s\n", ttToStr(op).c_str());
        break;
      }
    }

    // 变量赋值
    case Ast::AstType::ASSIGN:
    {
      auto a = reinterpret_cast<VarAssignAst*>(ast);
      context->insert({ a->name, a->value});
      return eval(a->value, context);
    }

    // 使用变量
    case Ast::AstType::ACCESS:
    {
      VarAccessAst* a = reinterpret_cast<VarAccessAst*>(ast);
      if (context->count(a->ident))
      {
        Ast* value = context->at(a->ident);
        return eval(value, context);
      }
      else
      {
        printf("Eval Error: undefined %s\n", a->ident.c_str());
        return 0;
      }
    }

    case Ast::AstType::MEMBER:
    {
      MemberAst* a = reinterpret_cast<MemberAst*>(ast);
      double res = 0;
      for (auto it: a->statements)
      {
        res = eval(it, context);
      }
      return res;
    }
    default:
      printf("Eval Error: error ast\n");
      return 0;
    }
  }
};
