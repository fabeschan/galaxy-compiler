%{
#include <cstdio>
#include <iostream>
#include <vector>
#include <string>
#include "ast.hpp"

// stuff from flex that bison needs to know about:
extern "C" int yylex();
extern "C" int yyparse();
extern "C" FILE *yyin;
extern int linenum; 
extern char* yytext;

using namespace std;
vector<string> typedef_table;
NBlock *programBlock; /* the top level root node of our final AST */

void yyerror(const char *s);
int sym_type(const char *);
void foundtoken(const char *s, const char *p);

// class Node;
//     class NExpression; //<expr> numeric expr <exprvec> call_args
//         class NInteger;
//         class NFixed;
//         class NIdentifier; //<ident> ident
//         class NMethodCall;
//         class NBinaryOperator;
//         class NAssignment;
//         class NBlock;       //<stmt> program stmts block
//     class NStatement;   //<stmt> stmt var_decl func_decl
//         class NExpressionStatement;
//         class NVariableDeclaration; //<varvec> func_decl_args
//         class NFunctionDeclaration;
%}

/*
external:
    expression (need to rename to expressionlist)
        : expression
        | expression ',' expression
    assignment_expression
    constant_expression (any expression other than an assignment_expr)

primary_expression
postfix_expression
unary_expression
binary_expression:
    : unary_expression
    | binary_expression BINARY_OP unary_expression
    
assignment_expression: unary_expression assignment_operator assignment_expression

*/



/* Represents the many different ways we can access our data */
%union {
    std::string *str;
    int token;
    Node *node;
    NBlock *block;
    NExpression *expr;
    NStatement *stmt;
    NIdentifier *ident;
    NVariableDeclaration *var_decl;
    std::vector<NVariableDeclaration*> *varvec;
    std::vector<NExpression*> *exprvec;
}

/* Terminal symbols */
%token<str>     IDENTIFIER I_CONSTANT F_CONSTANT STRING_LITERAL
%token<str>     TYPEDEF_NAME ENUMERATION_CONSTANT
%token<token>   LEFT_OP RIGHT_OP LE_OP GE_OP EQ_OP NE_OP
%token<token>   AND_OP OR_OP MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN
%token<token>   SUB_ASSIGN LEFT_ASSIGN RIGHT_ASSIGN AND_ASSIGN
%token<token>   XOR_ASSIGN OR_ASSIGN

%token<token>   TYPEDEF EXTERN STATIC
%token<token>   CONST ORDER ABILCMD REGION
%token<token>   BOOL CHAR INT FIXED UNIT UNITGROUP POINT VOID STRING
%token<token>   STRUCT UNION ENUM

%token<token>   IF ELSE WHILE CONTINUE BREAK RETURN

/* %token<block>   program */
%type<token>    unary_operator assignment_operator
%type<ident>    identifier
%type<expr>     constant enumeration_constant string
%type<expr>     primary_expression binary_expression
%type<expr>     postfix_expression unary_expression assignment_expression
%type<expr>     expression constant_expression
%type<stmt>     statement compound_statement expression_statement
%type<stmt>     selection_statement iteration_statement jump_statement

%start program

/* Order of Precedence */
/* 
%<left>     ','
%<right>    assignment_operator
%<left>     OR_OP
%<left>     AND_OP
%<left>     '|'
%<left>     '^'
%<left>     '&'
%<left>     EQ_OP NE_OP
%<left>     '<' '>' LE_OP GE_OP
%<left>     LEFT_OP RIGHT_OP
%<left>     '+' '-'
%<left>     '*' '/' '%'
%<right>    unary_operator
%<left>     post-fix expr

*/

%%

identifier
    : IDENTIFIER { foundtoken("id", $1->c_str()); $$ = new NIdentifier(*$1); delete $1; }
    ;

primary_expression
    : identifier
    | constant
    | string
    | '(' expression ')'
    ;

constant
    : I_CONSTANT { foundtoken("integer", $1->c_str()); $$ = new NInteger(atol($1->c_str())); delete $1; }
    | F_CONSTANT { foundtoken("fixed", $1->c_str()); $$ = new NFixed(atof($1->c_str())); delete $1; }
    | ENUMERATION_CONSTANT  /* after it has been defined as such */
    ;

enumeration_constant        /* before it has been defined as such */
    : identifier
    ;

string
    : STRING_LITERAL { foundtoken("string", $1->c_str()); }
    ;

postfix_expression
    : primary_expression
    | postfix_expression '[' expression ']'
    | postfix_expression '(' ')'
    | postfix_expression '(' argument_expression_list ')'
    | postfix_expression '.' identifier
    | '(' type_name ')' '{' initializer_list '}'
    | '(' type_name ')' '{' initializer_list ',' '}'
    ;

argument_expression_list
    : assignment_expression
    | argument_expression_list ',' assignment_expression
    ;

unary_expression
    : postfix_expression
    | unary_operator unary_expression
    ;

unary_operator
    : '+'
    | '-'
    | '~'
    | '!'
    ;

binary_expression
    : unary_expression
    | binary_expression '*' unary_expression
    | binary_expression '/' unary_expression
    | binary_expression '%' unary_expression
    | binary_expression '+' unary_expression
    | binary_expression '-' unary_expression
    | binary_expression LEFT_OP unary_expression
    | binary_expression RIGHT_OP unary_expression
    | binary_expression '<' unary_expression
    | binary_expression '>' unary_expression
    | binary_expression LE_OP unary_expression
    | binary_expression GE_OP unary_expression
    | binary_expression EQ_OP unary_expression
    | binary_expression NE_OP unary_expression
    | binary_expression '&' unary_expression
    | binary_expression '^' unary_expression
    | binary_expression '|' unary_expression
    | binary_expression AND_OP unary_expression
    | binary_expression OR_OP unary_expression
    ;

assignment_expression
    : binary_expression
    | unary_expression assignment_operator assignment_expression
        { $$ = new NBinaryOperator(*$1, $2, *$3); }
    ;

assignment_operator
    : '='
    | MUL_ASSIGN | DIV_ASSIGN | MOD_ASSIGN
    | ADD_ASSIGN | SUB_ASSIGN
    | LEFT_ASSIGN | RIGHT_ASSIGN
    | AND_ASSIGN | XOR_ASSIGN | OR_ASSIGN
    ;

expression
    : assignment_expression
    | expression ',' assignment_expression
    ;

constant_expression
    : binary_expression    /* with constraints */
    ;

declaration
    : declaration_specifiers ';'
    | declaration_specifiers init_declarator_list ';'
    ;

declaration_specifiers
    : storage_class_specifier declaration_specifiers
    | storage_class_specifier
    | type_specifier declaration_specifiers
    | type_specifier
    | type_qualifier declaration_specifiers
    | type_qualifier
    ;

init_declarator_list /* ex: int i=4, string s="a", ... */
    : init_declarator
    | init_declarator_list ',' init_declarator
    ;

init_declarator
    : declarator '=' initializer
    | declarator
    ;

storage_class_specifier
    : TYPEDEF   /* identifiers must be flagged as TYPEDEF_NAME */
    | EXTERN | STATIC
    ;

type_specifier
    : VOID | ABILCMD | CHAR
    | INT | FIXED | STRING
    | BOOL | UNIT | UNITGROUP
    | ORDER | POINT | REGION
    | struct_or_union_specifier
    | enum_specifier
    | TYPEDEF_NAME      /* after it has been defined as such */
    ;

struct_or_union_specifier
    : struct_or_union '{' struct_declaration_list '}'
    | struct_or_union identifier '{' struct_declaration_list '}'
    | struct_or_union identifier
    ;

struct_or_union
    : STRUCT
    | UNION
    ;

struct_declaration_list
    : struct_declaration
    | struct_declaration_list struct_declaration
    ;

struct_declaration
    : specifier_qualifier_list ';'  /* for anonymous struct/union */
    | specifier_qualifier_list declarator_list ';'
    ;

specifier_qualifier_list
    : type_specifier specifier_qualifier_list
    | type_specifier
    | type_qualifier specifier_qualifier_list
    | type_qualifier
    ;

declarator_list
    : declarator
    | declarator_list ',' declarator
    ;

enum_specifier
    : ENUM '{' enumerator_list '}'
    | ENUM '{' enumerator_list ',' '}'
    | ENUM identifier '{' enumerator_list '}'
    | ENUM identifier '{' enumerator_list ',' '}'
    | ENUM identifier
    ;

enumerator_list
    : enumerator
    | enumerator_list ',' enumerator
    ;

enumerator  /* identifiers must be flagged as ENUMERATION_CONSTANT */
    : enumeration_constant '=' constant_expression
    | enumeration_constant
    ;

type_qualifier
    : CONST
    ;

declarator
    : direct_declarator
    ;

direct_declarator
    : identifier /* { $$ = new NIdentifier(*$1); delete $1; } */
    | '(' declarator ')'
    | direct_declarator '[' ']'
    | direct_declarator '[' '*' ']'
    | direct_declarator '[' STATIC type_qualifier_list assignment_expression ']'
    | direct_declarator '[' STATIC assignment_expression ']'
    | direct_declarator '[' type_qualifier_list '*' ']'
    | direct_declarator '[' type_qualifier_list STATIC assignment_expression ']'
    | direct_declarator '[' type_qualifier_list assignment_expression ']'
    | direct_declarator '[' type_qualifier_list ']'
    | direct_declarator '[' assignment_expression ']'
    | direct_declarator '(' parameter_type_list ')'
    | direct_declarator '(' ')'
    | direct_declarator '(' identifier_list ')'
    ;

type_qualifier_list
    : type_qualifier
    | type_qualifier_list type_qualifier
    ;

parameter_type_list
    : parameter_list
    ;

parameter_list
    : parameter_declaration
    | parameter_list ',' parameter_declaration
    ;

parameter_declaration
    : declaration_specifiers declarator
    | declaration_specifiers abstract_declarator
    | declaration_specifiers
    ;

identifier_list
    : identifier
    | identifier_list ',' identifier
    ;

type_name
    : specifier_qualifier_list abstract_declarator
    | specifier_qualifier_list
    ;

abstract_declarator
    : direct_abstract_declarator
    ;

direct_abstract_declarator
    : '(' abstract_declarator ')'
    | '[' ']'
    | '[' '*' ']'
    | '[' STATIC type_qualifier_list assignment_expression ']'
    | '[' STATIC assignment_expression ']'
    | '[' type_qualifier_list STATIC assignment_expression ']'
    | '[' type_qualifier_list assignment_expression ']'
    | '[' type_qualifier_list ']'
    | '[' assignment_expression ']'
    | direct_abstract_declarator '[' ']'
    | direct_abstract_declarator '[' '*' ']'
    | direct_abstract_declarator '[' STATIC type_qualifier_list assignment_expression ']'
    | direct_abstract_declarator '[' STATIC assignment_expression ']'
    | direct_abstract_declarator '[' type_qualifier_list assignment_expression ']'
    | direct_abstract_declarator '[' type_qualifier_list STATIC assignment_expression ']'
    | direct_abstract_declarator '[' type_qualifier_list ']'
    | direct_abstract_declarator '[' assignment_expression ']'
    | '(' ')'
    | '(' parameter_type_list ')'
    | direct_abstract_declarator '(' ')'
    | direct_abstract_declarator '(' parameter_type_list ')'
    ;

initializer
    : '{' initializer_list '}'
    | '{' initializer_list ',' '}'
    | assignment_expression
    ;

initializer_list
    : designation initializer
    | initializer
    | initializer_list ',' designation initializer
    | initializer_list ',' initializer
    ;

designation
    : designator_list '='
    ;

designator_list
    : designator
    | designator_list designator
    ;

designator
    : '[' constant_expression ']'
    | '.' identifier
    ;

statement
    : compound_statement
    | expression_statement
    | selection_statement
    | iteration_statement
    | jump_statement
    ;

compound_statement
    : '{' '}'
    | '{'  block_item_list '}'
    ;

block_item_list
    : block_item
    | block_item_list block_item
    ;

block_item
    : declaration
    | statement
    ;

expression_statement
    : ';'
    | expression ';'
    ;

selection_statement
    : IF '(' expression ')' statement ELSE statement
    | IF '(' expression ')' statement
    ;

iteration_statement
    : WHILE '(' expression ')' statement
    ;

jump_statement
    : CONTINUE ';'
    | BREAK ';'
    | RETURN ';'
    | RETURN expression ';'
    ;

program
    : translation_unit /* { programBlock = $1; } */
    ;

translation_unit
    : external_declaration
    | translation_unit external_declaration
    ;

external_declaration
    : function_definition
    | declaration
    ;

function_definition
    : declaration_specifiers declarator declaration_list compound_statement
    | declaration_specifiers declarator compound_statement

declaration_list
    : declaration
    | declaration_list declaration
    ;

%%

int main(int argc, char *argv[]) {
    // open a file handle to a particular file:
    FILE *myfile = fopen(argv[1], "r");

    // make sure it is valid:
    if (!myfile) {
        cout << "Error: cannot open file" << endl;
        return -1;
    }
    // set flex to read from it instead of defaulting to STDIN:
    yyin = myfile;
    
    // parse through the input until there is no more:
    if(!yyparse())
        printf("\nParsing complete\n");
    else
        printf("\nParsing failed\n");
    fclose(myfile);
    return 0;
}

void yyerror(const char *s) {
    printf("%d: parse error: %s %s: \n", linenum, s, yytext);
    // might as well halt now:
    //exit(-1);
}

int sym_type(const char *s){
    string str = string(s);
    for (vector<string>::iterator it = typedef_table.begin(); it != typedef_table.end(); ++it){
        if (str == *it) return TYPEDEF_NAME;
    }
    return IDENTIFIER;
}

void foundtoken(const char *s, const char *p){
    cout << linenum << ": found " << s << ": " << p << endl;
}
