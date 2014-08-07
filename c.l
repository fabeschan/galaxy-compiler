%e  1019
%p  2807
%n  371
%k  284
%a  1213
%o  1117

O   [0-7]
D   [0-9]
NZ  [1-9]
L   [a-zA-Z_]
A   [a-zA-Z_0-9]
H   [a-fA-F0-9]
HP  (0[xX])
E   ([Ee][+-]?{D}+)
P   ([Pp][+-]?{D}+)
FS  (f|F|l|L)
IS  (((u|U)(l|L|ll|LL)?)|((l|L|ll|LL)(u|U)?))
CP  (u|U|L)
SP  (u8|u|U|L)
ES  (\\(['"\?\\abfnrtv]|[0-7]{1,3}|x[a-fA-F0-9]+))
WS  [ \t\v\n\f]

%x IN_COMMENT

%{
#include <iostream>
#include "c.y.hpp"
#include "ast.hpp"
using namespace std;
#define YY_DECL extern "C" int yylex()

extern void yyerror(const char *);  /* prints grammar violation message */
extern int sym_type(const char *);  /* returns type from symbol table */

//#define sym_type(identifier) IDENTIFIER /* with no symbol table, fake it */

static void comment(void);
static int check_type(void);

int linenum = 1;

#define TOKEN(t) do { \
    printf("%d: found keyword: %s\n", linenum, yytext); \
    return (yylval.token = t); \
    } while (0)

#define SAVETOKEN(t) do { \
    yylval.str = new std::string(yytext, yyleng); \
    return t; \
    } while (0)

#define DISABLED() yyterminate()

%}

alpha [a-zA-Z]
digit [0-9]

%%

<INITIAL>{
"/*"              BEGIN(IN_COMMENT);
}
<IN_COMMENT>{
"*/"      BEGIN(INITIAL);
[^*\n]+   // eat comment in chunks
"*"       // eat the lone star
\n        ++linenum;
} { /* return (COMMENT); */ }
"//".*                  { /* consume //-comment */ }

"break"                 { TOKEN(BREAK); }
"bool"                  { TOKEN(BOOL); }
"case"                  { TOKEN(CASE); }
"char"                  { TOKEN(CHAR); }
"const"                 { TOKEN(CONST); }
"continue"              { TOKEN(CONTINUE); }
"default"               { TOKEN(DEFAULT); }
"do"                    { TOKEN(DO); }
"double"                { TOKEN(DOUBLE); }
"else"                  { TOKEN(ELSE); }
"enum"                  { TOKEN(ENUM); }
"extern"                { TOKEN(EXTERN); }
"float"                 { TOKEN(FLOAT); }
"fixed"                 { TOKEN(FIXED); }
"for"                   { TOKEN(FOR); }
"goto"                  { TOKEN(GOTO); }
"if"                    { TOKEN(IF); }
"inline"                { TOKEN(INLINE); }
"int"                   { TOKEN(INT); }
"long"                  { TOKEN(LONG); }
"restrict"              { TOKEN(RESTRICT); }
"return"                { TOKEN(RETURN); }
"short"                 { TOKEN(SHORT); }
"signed"                { TOKEN(SIGNED); }
"string"                { TOKEN(STRING); }
"sizeof"                { TOKEN(SIZEOF); }
"static"                { TOKEN(STATIC); }
"struct"                { TOKEN(STRUCT); }
"switch"                { TOKEN(SWITCH); }
"typedef"               { TOKEN(TYPEDEF); }
"union"                 { TOKEN(UNION); }
"unsigned"              { TOKEN(UNSIGNED); }
"void"                  { TOKEN(VOID); }
"volatile"              { TOKEN(VOLATILE); }
"while"                 { TOKEN(WHILE); }
"_Alignas"                              { TOKEN(ALIGNAS); }
"_Alignof"                              { TOKEN(ALIGNOF); }
"_Atomic"                               { TOKEN(ATOMIC); }
"_Bool"                                 { TOKEN(BOOL); }
"_Complex"                              { TOKEN(COMPLEX); }
"_Imaginary"                            { TOKEN(IMAGINARY); }
"_Noreturn"                             { TOKEN(NORETURN); }
"_Static_assert"                        { TOKEN(STATIC_ASSERT); }
"_Thread_local"                         { TOKEN(THREAD_LOCAL); }
"__func__"                              { TOKEN(FUNC_NAME); }

{L}{A}*                 { SAVETOKEN(check_type()); }

{HP}{H}+{IS}?                   { SAVETOKEN(I_CONSTANT); }      /* hex integer */
{NZ}{D}*{IS}?                   { SAVETOKEN(I_CONSTANT); }      /* dec integer */
"0"{O}*{IS}?                    { SAVETOKEN(I_CONSTANT); }      /* oct integer */
{CP}?"'"([^'\\\n]|{ES})+"'"     { SAVETOKEN(I_CONSTANT); }

{D}+{E}{FS}?                    { SAVETOKEN(F_CONSTANT); }
{D}*"."{D}+{E}?{FS}?            { SAVETOKEN(F_CONSTANT); }
{D}+"."{E}?{FS}?                { SAVETOKEN(F_CONSTANT); }
{HP}{H}+{P}{FS}?                { SAVETOKEN(F_CONSTANT); }
{HP}{H}*"."{H}+{P}{FS}?         { SAVETOKEN(F_CONSTANT); }
{HP}{H}+"."{P}{FS}?             { SAVETOKEN(F_CONSTANT); }

({SP}?\"([^"\\\n]|{ES})*\"{WS}*)+   { SAVETOKEN(STRING_LITERAL); }

"..."                   { TOKEN(ELLIPSIS); }
">>="                   { TOKEN(RIGHT_ASSIGN); }
"<<="                   { TOKEN(LEFT_ASSIGN); }
"+="                    { TOKEN(ADD_ASSIGN); }
"-="                    { TOKEN(SUB_ASSIGN); }
"*="                    { TOKEN(MUL_ASSIGN); }
"/="                    { TOKEN(DIV_ASSIGN); }
"%="                    { TOKEN(MOD_ASSIGN); }
"&="                    { TOKEN(AND_ASSIGN); }
"^="                    { TOKEN(XOR_ASSIGN); }
"|="                    { TOKEN(OR_ASSIGN); }
">>"                    { TOKEN(RIGHT_OP); }
"<<"                    { TOKEN(LEFT_OP); }
"++"                    { TOKEN(INC_OP); }
"--"                    { TOKEN(DEC_OP); }
"->"                    { TOKEN(PTR_OP); }
"&&"                    { TOKEN(AND_OP); }
"||"                    { TOKEN(OR_OP); }
"<="                    { TOKEN(LE_OP); }
">="                    { TOKEN(GE_OP); }
"=="                    { TOKEN(EQ_OP); }
"!="                    { TOKEN(NE_OP); }
";"                 { return ';'; }
("{"|"<%")          { return '{'; }
("}"|"%>")          { return '}'; }
","                 { return ','; }
":"                 { return ':'; }
"="                 { return '='; }
"("                 { return '('; }
")"                 { return ')'; }
("["|"<:")          { return '['; }
("]"|":>")          { return ']'; }
"."                 { return '.'; }
"&"                 { return '&'; }
"!"                 { return '!'; }
"~"                 { return '~'; }
"-"                 { return '-'; }
"+"                 { return '+'; }
"*"                 { return '*'; }
"/"                 { return '/'; }
"%"                 { return '%'; }
"<"                 { return '<'; }
">"                 { return '>'; }
"^"                 { return '^'; }
"|"                 { return '|'; }
"?"                 { return '?'; }

[ \t\v\f]           { /* whitespace separates tokens */ }
[ \n]               { ++linenum; }
.                   { yyterminate(); /* not sure: terminate or skip bad characters */ }

%%

int yywrap(void){       /* called at end of input */
    return 1;           /* terminate now */
}

static int check_type(void) {
    switch (sym_type(yytext))
    {
    case TYPEDEF_NAME:                /* previously defined */
        return TYPEDEF_NAME;
    case ENUMERATION_CONSTANT:        /* previously defined */
        return ENUMERATION_CONSTANT;
    default:                          /* includes undefined */
        return IDENTIFIER;
    }
}
