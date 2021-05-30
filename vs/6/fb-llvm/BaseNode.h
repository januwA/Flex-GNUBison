#pragma once
#include <iostream>
#include <map>
#include <string>
#include <vector>

namespace yy
{
  enum class NT
  {
    NUMBER,
    VARIABLE,
    BINARY,
    CALL,
    PROPTYPE,
    FUNCTION,
    IF,
    FOR,
  };

  class BaseNode
  {
  public:
    virtual ~BaseNode() {}
    virtual NT id() = 0;
  };

  class NumberNode : public BaseNode
  {
  public:
    std::string Val;
    double dval;

    NumberNode(std::string Val) : Val(Val)
    {
      dval = std::stod(Val);
    }
    ~NumberNode() {}
    virtual NT id() { return NT::NUMBER; };
  };

  class VariableNode : public BaseNode
  {
  public:
    std::string Name;

    VariableNode(const std::string &Name) : Name(Name) {}
    ~VariableNode() {}
    virtual NT id() { return NT::VARIABLE; };
  };

  class BinaryNode : public BaseNode
  {
  public:
    int Op;
    BaseNode *left;
    BaseNode *right;

    BinaryNode(int op, BaseNode *left, BaseNode *right)
        : Op(op), left(left), right(right) {}
    ~BinaryNode()
    {
      delete left;
      delete right;
    }
    virtual NT id() { return NT::BINARY; };
  };

  class CallNode : public BaseNode
  {
  public:
    std::string Callee;
    std::vector<BaseNode *> Args;

    CallNode(const std::string &Callee, std::vector<BaseNode *> Args)
        : Callee(Callee), Args(Args) {}
    ~CallNode()
    {
      for (auto a : Args)
        delete a;
    }
    virtual NT id() { return NT::CALL; };
  };

  /*
    extern sin(arg);
    extern cos(arg);
    extern atan2(arg1 arg2);

    def unary!(v)
    def binary> 10 (LHS RHS)
  */
  class PrototypeNode : public BaseNode
  {
  public:
    std::string Name;
    std::vector<std::string> Args;
    PrototypeNode(const std::string &name, std::vector<std::string> Args)
        : Name(name), Args(Args){}
    ~PrototypeNode() {}

    virtual NT id() { return NT::PROPTYPE; };
  };

  /*
  def fib(x)
    if x < 3 then
      1
   else
     fib(x-1)+fib(x-2)
  */
  class FunctionNode : public BaseNode
  {
  public:
    PrototypeNode *Proto;
    BaseNode *Body;

    FunctionNode(PrototypeNode *Proto, BaseNode *Body)
        : Proto(Proto), Body(Body) {}
    ~FunctionNode()
    {
      delete Proto;
      delete Body;
    }
    virtual NT id() { return NT::FUNCTION; };
  };

  class IfNode : public BaseNode
  {
  public:
    BaseNode *conditionNode;
    BaseNode *thenNode;
    BaseNode *elseNode;
    IfNode(BaseNode *conditionNode, BaseNode *thenNode, BaseNode *elseNode) : conditionNode(conditionNode), thenNode(thenNode), elseNode(elseNode) {}
    ~IfNode()
    {
      delete conditionNode;
      delete thenNode;
      delete elseNode;
    }
    virtual NT id() override { return NT::IF; };
  };

  class ForNode : public BaseNode
  {
  public:
    std::string VarName;
    BaseNode *start;
    BaseNode *end;
    BaseNode *step; // 可选，默认1.0
    BaseNode *body;
    ForNode(std::string VarName, BaseNode *start, BaseNode *end, BaseNode *step, BaseNode *body) : VarName(VarName), start(start), end(end), step(step), body(body) {}
    ~ForNode()
    {
      delete start;
      delete end;
      if (step != NULL)
        delete step;
      delete body;
    }
    virtual NT id() override { return NT::FOR; };
  };
}
