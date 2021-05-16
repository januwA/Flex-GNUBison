#include <iostream>
#include "parser.h"

using namespace std;

extern FILE* yyin, * yyout;

int main()
{
  yyparse();
  return 0;
}

void yyerror(const char* msg)
{
  cout << "Error: " << msg << endl;
}
