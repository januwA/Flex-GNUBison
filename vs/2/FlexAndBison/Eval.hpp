#pragma once

#include "Ast.h"

class Eval
{
public:
  Eval() {};


  double eval(Ast* ast)
  {
    switch (ast->id())
    {
    case Ast::AstType::NUMBER:
      return reinterpret_cast<NumberAst*>(ast)->value;
    case Ast::AstType::BINARY:
    {
      double left = eval(reinterpret_cast<BinaryAst*>(ast)->left);
      double right = eval(reinterpret_cast<BinaryAst*>(ast)->right);
      int op = reinterpret_cast<BinaryAst*>(ast)->op;
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
        throw std::exception(("binary expr error op " + ttToStr(op)).c_str());
        break;
      }
    }
    default:
      throw std::exception("error ast.\n");
      break;
    }
  }
};
