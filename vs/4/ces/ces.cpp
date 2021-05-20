#include <iostream>
#include "parser.h"

using namespace std;

typedef struct yy_buffer_state* YY_BUFFER_STATE;
extern YY_BUFFER_STATE yy_scan_string(const char* str);
extern void yy_delete_buffer(YY_BUFFER_STATE buffer);

int main()
{
  YY_BUFFER_STATE state = yy_scan_string("1 + 2 * 3");
  double result = 0;
  yyparse(&result);
  yy_delete_buffer(state);

  printf("=>%lf\n", result);
  return 0;
}


void yyerror(double* result, const char* msg)
{
  cout << "Error: " << msg << endl;
}
