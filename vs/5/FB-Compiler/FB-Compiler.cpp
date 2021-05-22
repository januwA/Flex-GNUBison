#include <iostream>
#include "FBContext.h"
#include "parser.h"

typedef struct yy_buffer_state* YY_BUFFER_STATE;
extern YY_BUFFER_STATE yy_math_scan_string(const char* str);
extern void yy_math_delete_buffer(YY_BUFFER_STATE buffer);

int main()
{
  YY_BUFFER_STATE state = yy_math_scan_string("1 + 2 * 3");
  yy_math::FBContext ctx;
  yy_math::Parser parser(&ctx);
  parser.parse();
  yy_math_delete_buffer(state);
  printf("=>%lf\n", ctx.result);
  return 0;
}

