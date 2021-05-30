#include <iostream>

#include "parser.h"
#include "BaseNode.h"
#include "Interpreter.h"

typedef struct yy_buffer_state* YY_BUFFER_STATE;
extern YY_BUFFER_STATE yy_scan_string(const char* str);
extern void yy_delete_buffer(YY_BUFFER_STATE buffer);

int main()
{
  InitializeAllTargetInfos();
  InitializeAllTargets();
  InitializeAllTargetMCs();
  InitializeAllAsmParsers();
  InitializeAllAsmPrinters();

  //YY_BUFFER_STATE state = yy_scan_string("1+2+3");
  YY_BUFFER_STATE state = yy_scan_string("def myadd(a,b) a + b");
  yy::BaseNode* node = nullptr;
  yy::parser p(&node);
  p.parse();
  yy_delete_buffer(state);

  if (node)
  {
    yy::Interpreter interpreter;
    auto topFunction = reinterpret_cast<llvm::Function*>(interpreter.interpreter(node));
    double val = interpreter.jit();
    printf("%lf\n", val);
    delete node;
  }
  return 0;
}
