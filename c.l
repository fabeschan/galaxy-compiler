%{
#include <iostream>
using namespace std;
#define YY_DECL extern "C" int yylex()

int linenum = 1;
%}

%%

[ \t]               ;
[ \n]               { ++linenum; }
[0-9]+\.[0-9]+      { printf("%d: Found a float: %s\n", linenum, yytext); }
[0-9]+              { printf("%d: Found an integer: %s\n", linenum, yytext); }
[a-zA-Z0-9]+        { printf("%d: Found a string: %s\n", linenum, yytext); }
.                   ;

%%

