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
"//".*                                    { /* consume //-comment */ }

"auto"                  { TOKEN(AUTO); }
"break"                 { TOKEN(BREAK); }
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
"for"                   { TOKEN(FOR); }
"goto"                  { TOKEN(GOTO); }
"if"                    { TOKEN(IF); }
"inline"                { TOKEN(INLINE); }
"int"                   { TOKEN(INT); }
"long"                  { TOKEN(LONG); }
"register"              { TOKEN(REGISTER); }
"restrict"              { TOKEN(RESTRICT); }
"return"                { TOKEN(RETURN); }
"short"                 { TOKEN(SHORT); }
"signed"                { TOKEN(SIGNED); }
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
"_Alignas"                              { return ALIGNAS; }
"_Alignof"                              { return ALIGNOF; }
"_Atomic"                               { return ATOMIC; }
"_Bool"                                 { return BOOL; }
"_Complex"                              { return COMPLEX; }
"_Generic"                              { return GENERIC; }
"_Imaginary"                            { return IMAGINARY; }
"_Noreturn"                             { return NORETURN; }
"_Static_assert"                        { return STATIC_ASSERT; }
"_Thread_local"                         { return THREAD_LOCAL; }
"__func__"                              { return FUNC_NAME; }

{L}{A}*                 { return check_type(); }

{HP}{H}+{IS}?               { return I_CONSTANT; }      /* hex integer */
{NZ}{D}*{IS}?               { return I_CONSTANT; }      /* dec integer */
"0"{O}*{IS}?                { return I_CONSTANT; }      /* oct integer */
{CP}?"'"([^'\\\n]|{ES})+"'"     { return I_CONSTANT; }

{D}+{E}{FS}?                { return F_CONSTANT; }
{D}*"."{D}+{E}?{FS}?            { return F_CONSTANT; }
{D}+"."{E}?{FS}?            { return F_CONSTANT; }
{HP}{H}+{P}{FS}?            { return F_CONSTANT; }
{HP}{H}*"."{H}+{P}{FS}?         { return F_CONSTANT; }
{HP}{H}+"."{P}{FS}?         { return F_CONSTANT; }

({SP}?\"([^"\\\n]|{ES})*\"{WS}*)+   { return STRING_LITERAL; }

"..."                   { return ELLIPSIS; }
">>="                   { return RIGHT_ASSIGN; }
"<<="                   { return LEFT_ASSIGN; }
"+="                    { return ADD_ASSIGN; }
"-="                    { return SUB_ASSIGN; }
"*="                    { return MUL_ASSIGN; }
"/="                    { return DIV_ASSIGN; }
"%="                    { return MOD_ASSIGN; }
"&="                    { return AND_ASSIGN; }
"^="                    { return XOR_ASSIGN; }
"|="                    { return OR_ASSIGN; }
">>"                    { return RIGHT_OP; }
"<<"                    { return LEFT_OP; }
"++"                    { return INC_OP; }
"--"                    { return DEC_OP; }
"->"                    { return PTR_OP; }
"&&"                    { return AND_OP; }
"||"                    { return OR_OP; }
"<="                    { return LE_OP; }
">="                    { return GE_OP; }
"=="                    { return EQ_OP; }
"!="                    { return NE_OP; }
";"                 { return ';'; }
("{"|"<%")              { return '{'; }
("}"|"%>")              { return '}'; }
","                 { return ','; }
":"                 { return ':'; }
"="                 { return '='; }
"("                 { return '('; }
")"                 { return ')'; }
("["|"<:")              { return '['; }
("]"|":>")              { return ']'; }
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

int yywrap(void)        /* called at end of input */
{
    return 1;           /* terminate now */
}

static int check_type(void)
{
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
