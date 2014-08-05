%{
#include <iostream>
#include "c.y.hpp"
using namespace std;
#define YY_DECL extern "C" int yylex()

int linenum = 1;
%}

alpha [a-zA-Z]
digit [0-9]

%%

[ \t]       ;
[ \n]       { ++linenum; }
int         { printf("%d: Found keyword: %s\n", linenum, yytext); return INT; }
float       { printf("%d: Found keyword: %s\n", linenum, yytext); return FLOAT; }
char        { printf("%d: Found keyword: %s\n", linenum, yytext); return CHAR; }
void        { printf("%d: Found keyword: %s\n", linenum, yytext); return VOID; }
double      { printf("%d: Found keyword: %s\n", linenum, yytext); return DOUBLE; }
for         { printf("%d: Found keyword: %s\n", linenum, yytext); return FOR; }
while       { printf("%d: Found keyword: %s\n", linenum, yytext); return WHILE; }
if          { printf("%d: Found keyword: %s\n", linenum, yytext); return IF; }
else        { printf("%d: Found keyword: %s\n", linenum, yytext); return ELSE; }
printf      { printf("%d: Found keyword: %s\n", linenum, yytext); return PRINTF; }
struct      { printf("%d: Found keyword: %s\n", linenum, yytext); return STRUCT; }
^"#include ".+      ;
{digit}+    { printf("%d: Found a num: %s\n", linenum, yytext); return NUM; }
{alpha}({alpha}|{digit})*       return ID;
"<="        { printf("%d: Found an op: %s\n", linenum, yytext); return LE; }
">="        { printf("%d: Found an op: %s\n", linenum, yytext); return GE; }
"=="        { printf("%d: Found an op: %s\n", linenum, yytext); return EQ; }
"!="        { printf("%d: Found an op: %s\n", linenum, yytext); return NE; }
">"         { printf("%d: Found an op: %s\n", linenum, yytext); return GT; }
"<"         { printf("%d: Found an op: %s\n", linenum, yytext); return LT; }
"."         { printf("%d: Found an op: %s\n", linenum, yytext); return DOT; }
\/\/.*      ;
\/\*(.*\n)*.*\*\/       ;
.           { return yytext[0]; }
%%

