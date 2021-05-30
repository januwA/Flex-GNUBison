#pragma once

#include "llvm/ADT/APFloat.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Support/TargetSelect.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Transforms/InstCombine/InstCombine.h"
#include "llvm/Transforms/Scalar.h"
#include "llvm/Transforms/Scalar/GVN.h"
#include <llvm/Support/Host.h>
#include <llvm/Support/TargetRegistry.h>
#include <llvm/ExecutionEngine/MCJIT.h>
#include <algorithm>
#include <cassert>
#include <cctype>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <map>
#include <memory>
#include <string>
#include <vector>

#include "./KaleidoscopeJIT.h"
#include "BaseNode.h"
#include "parser.h"


using namespace llvm;
using namespace llvm::orc;

namespace yy
{
  class Interpreter
  {
  public:
    std::unique_ptr<llvm::LLVMContext> TheContext;
    std::unique_ptr<llvm::Module> TheModule;
    std::unique_ptr<llvm::IRBuilder<>> Builder;            // IR 生成器
    std::unique_ptr<llvm::legacy::FunctionPassManager> FP; // 优化器

    std::map<std::string, llvm::Value*> NamedValues; // variables
    ExitOnError ExitOnErr;

    std::unique_ptr<KaleidoscopeJIT> TheJIT;
    Interpreter()
    {
      TheJIT = ExitOnErr(KaleidoscopeJIT::Create());
      InitializeModuleAndPassManager();
    }

    llvm::Value* interpreter(yy::BaseNode* node)
    {
      switch (node->id())
      {
      case NT::NUMBER:
        return visitNumber(reinterpret_cast<yy::NumberNode*>(node));
      case NT::BINARY:
        return visitBinary(reinterpret_cast<yy::BinaryNode*>(node));
      case NT::FUNCTION:
        return visitFunction(reinterpret_cast<yy::FunctionNode*>(node));
      case NT::CALL:
        return visitCall(reinterpret_cast<yy::CallNode*>(node));
      case NT::PROPTYPE:
        return visitPrototype(reinterpret_cast<yy::PrototypeNode*>(node));
      case NT::VARIABLE:
        return visitVariable(reinterpret_cast<yy::VariableNode*>(node));
      case NT::IF:
        return visitIf(reinterpret_cast<yy::IfNode*>(node));
      case NT::FOR:
        return visitFor(reinterpret_cast<yy::ForNode*>(node));
      default:
        break;
      }
    }

    double jit()
    {
      TheModule->print(llvm::errs(), nullptr);
      return 0;
      
      auto RT = TheJIT->getMainJITDylib().createResourceTracker();
      auto TSM = ThreadSafeModule(std::move(TheModule), std::move(TheContext));
      TheJIT->addModule(std::move(TSM), RT);
      InitializeModuleAndPassManager();

      auto ExprSymbol = ExitOnErr(TheJIT->lookup("__main"));
      double (*FP)() = (double (*)())(intptr_t)ExprSymbol.getAddress();
      auto val = FP();
      ExitOnErr(RT->remove());
      return val;
    }

  private:
    void InitializeModuleAndPassManager()
    {
      // 打开一个新的上下文和模块
      TheContext = std::make_unique<LLVMContext>();
      TheModule = std::make_unique<Module>("my jit", *TheContext);
      TheModule->setDataLayout(TheJIT->getDataLayout());

      // 为该模块创建一个新的构建器
      Builder = std::make_unique<IRBuilder<>>(*TheContext);

      // 优化器
      FP = std::make_unique<legacy::FunctionPassManager>(TheModule.get());
      FP->add(llvm::createInstructionCombiningPass()); // 组合指令优化
      FP->add(llvm::createReassociatePass());          // 重新关联表达式优化
      FP->add(llvm::createGVNPass());                  // 消除常用子表达式
      FP->add(llvm::createCFGSimplificationPass());    // 简化控制流图（删除无法访问的块等）
      FP->doInitialization();
    }

    // 返回没有body的函数
    llvm::Function* visitPrototype(PrototypeNode* node)
    {
      // 创建一个double类型的向量
      std::vector<llvm::Type*> Doubles(node->Args.size(), llvm::Type::getDoubleTy(*TheContext));

      // 创建一个函数类型
      llvm::FunctionType* FT = llvm::FunctionType::get(llvm::Type::getDoubleTy(*TheContext), Doubles, false);

      // 创建一个函数，并添加到模块中
      llvm::Function* F = llvm::Function::Create(FT, llvm::Function::ExternalLinkage, node->Name, TheModule.get());

      // 设置参数名
      unsigned Idx = 0;
      for (auto& Arg : F->args())
        Arg.setName(node->Args[Idx++]);

      return F;
    }

    llvm::Value* visitFunction(FunctionNode* node)
    {
      // printf("fun name:%s\n", node->Proto->Name.c_str());
      // 先检查函数是否已经创建
      llvm::Function* TheFunction = TheModule->getFunction(node->Proto->Name);

      // 不存在就创建
      if (!TheFunction)
        TheFunction = visitPrototype(node->Proto);

      // 创建一个新的基本块以开始插入。
      llvm::BasicBlock* BB = BasicBlock::Create(*TheContext, "entry", TheFunction);
      Builder->SetInsertPoint(BB);

      // 在NamedValues映射中记录函数参数
      NamedValues.clear();
      for (auto& Arg : TheFunction->args())
      {
        // printf("arg:%s\n", Arg.getName().str().c_str());
        NamedValues[Arg.getName().str()] = &Arg;
      }

      // function body
      llvm::Value* RetVal = interpreter(node->Body);

      // 创建return指令
      Builder->CreateRet(RetVal);

      // 验证生成的代码，检查一致性
      verifyFunction(*TheFunction);

      // 在函数返回前，优化函数
      FP->run(*TheFunction);

      TheModule->print(llvm::errs(), nullptr);

      return TheFunction;
    }

    llvm::Value* visitVariable(VariableNode* node)
    {
      // printf("name:%s\n", node->Name.c_str());
      llvm::Value* val = NamedValues[node->Name];
      if (!val)
        throw std::exception(("not define " + node->Name).c_str());
      return val;
    }
    llvm::Value* visitCall(CallNode* node)
    {
      // 在全局模块表中查找函数名称。
      llvm::Function* CalleeF = TheModule->getFunction(node->Callee);
      if (!CalleeF)
        throw std::exception("Unknown function referenced");

      // 检查参数数量
      if (CalleeF->arg_size() != node->Args.size())
        throw std::exception("Incorrect # arguments passed");

      std::vector<llvm::Value*> ArgsV;
      for (size_t i = 0, e = node->Args.size(); i != e; ++i)
      {
        ArgsV.push_back(interpreter(node->Args[i]));
        if (!ArgsV.back())
          return nullptr;
      }
      return Builder->CreateCall(CalleeF, ArgsV, "calltmp");
    }

    llvm::Value* visitBinary(BinaryNode* node)
    {
      // 使用Create创建指令
      llvm::Value* L = interpreter(node->left);
      llvm::Value* R = interpreter(node->right);
      switch (node->Op)
      {
      case yy::parser::token::PLUS:
        return Builder->CreateFAdd(L, R, "addtmp");
      case yy::parser::token::MINUS:
        return Builder->CreateFSub(L, R, "subtmp");
      case yy::parser::token::MUL:
        return Builder->CreateFMul(L, R, "multmp");
      case yy::parser::token::DIV:
        return Builder->CreateFDiv(L, R, "divtmp");
      case yy::parser::token::LT:
        L = Builder->CreateFCmpULT(L, R, "cmptmp");
        return Builder->CreateUIToFP(L, llvm::Type::getDoubleTy(*TheContext), "booltmp");
      case yy::parser::token::GT:
        L = Builder->CreateFCmpUGT(L, R, "cmptmp");
        return Builder->CreateUIToFP(L, llvm::Type::getDoubleTy(*TheContext), "booltmp");
      default:
        throw std::exception("invalid binary operator\n");
      }
    }

    llvm::Value* visitNumber(NumberNode* node)
    {
      // 获取数字常量
      return llvm::ConstantFP::get(*TheContext, llvm::APFloat(node->dval));
    }

    llvm::Value* visitIf(IfNode* node)
    {
      auto condition = interpreter(node->conditionNode);

      // 通过比较不等于0.0的值将条件转换为布尔值
      condition = Builder->CreateFCmpONE(condition, llvm::ConstantFP::get(*TheContext, llvm::APFloat(0.0)), "ifcond");

      auto TheFunc = Builder->GetInsertBlock()->getParent();

      // 创建块。将then块插入函数
      auto ThenBB = llvm::BasicBlock::Create(*TheContext, "then", TheFunc);
      auto ElseBB = llvm::BasicBlock::Create(*TheContext, "else");
      auto MergeBB = llvm::BasicBlock::Create(*TheContext, "ifcont");

      Builder->CreateCondBr(condition, ThenBB, ElseBB);

      Builder->SetInsertPoint(ThenBB); // SetInsertPoint 设置插入点
      auto ThenV = interpreter(node->thenNode);
      Builder->CreateBr(MergeBB);
      ThenBB = Builder->GetInsertBlock();

      TheFunc->getBasicBlockList().push_back(ElseBB);
      Builder->SetInsertPoint(ElseBB);
      auto ElseV = interpreter(node->elseNode);
      Builder->CreateBr(MergeBB);
      ElseBB = Builder->GetInsertBlock();

      TheFunc->getBasicBlockList().push_back(MergeBB);
      Builder->SetInsertPoint(MergeBB);
      auto PN = Builder->CreatePHI(llvm::Type::getDoubleTy(*TheContext), 2, "iftmp");
      PN->addIncoming(ThenV, ThenBB);
      PN->addIncoming(ElseV, ElseBB);

      return PN;
    }

    llvm::Value* visitFor(ForNode* node)
    {
      auto StartVal = interpreter(node->start);

      auto TheFunction = Builder->GetInsertBlock()->getParent();
      auto PreheaderBB = Builder->GetInsertBlock();
      auto LoopBB = llvm::BasicBlock::Create(*TheContext, "loop", TheFunction);

      // 插入从当前块到LoopBB,无条件跳到loop
      Builder->CreateBr(LoopBB);

      // 开始插入LoopBB
      Builder->SetInsertPoint(LoopBB);

      auto Variable = Builder->CreatePHI(llvm::Type::getDoubleTy(*TheContext), 2, node->VarName.c_str());
      Variable->addIncoming(StartVal, PreheaderBB);

      // 如果有一个现有的变量，我们必须还原它，所以现在保存它
      auto OldVal = NamedValues[node->VarName];
      NamedValues[node->VarName] = Variable;

      interpreter(node->body);
      auto StepVal = node->step ? interpreter(node->step) : llvm::ConstantFP::get(*TheContext, llvm::APFloat(1.0));

      auto NextVar = Builder->CreateFAdd(Variable, StepVal, "nextvar");

      auto EndCond = interpreter(node->end); // 1 of 0

      // 判断EndCond是否不等于0
      EndCond = Builder->CreateFCmpONE(EndCond, llvm::ConstantFP::get(*TheContext, llvm::APFloat(0.0)), "loopcond");

      auto LoopEndBB = Builder->GetInsertBlock();
      auto AfterBB = llvm::BasicBlock::Create(*TheContext, "afterloop", TheFunction);

      // 将条件分支插入Loop的末尾
      Builder->CreateCondBr(EndCond, LoopBB, AfterBB);

      Builder->SetInsertPoint(AfterBB);

      Variable->addIncoming(NextVar, LoopEndBB);

      if (OldVal)
        NamedValues[node->VarName] = OldVal;
      else
        NamedValues.erase(node->VarName);

      // for 表达式返回null(0.0)
      return llvm::Constant::getNullValue(llvm::Type::getDoubleTy(*TheContext));
    }
  };
}
