%{
#include <cstdio>
#include <iostream>
#include <vector>
#include <string>
#include <map>
#include "ast.hpp"

// stuff from flex that bison needs to know about:
extern "C" int yylex();
extern "C" int yyparse();
extern "C" FILE *yyin;
extern int linenum; 
extern char* yytext;

using namespace std;
vector<string> typedef_table;
map<string, int> type_table;
NBlock *programBlock; /* the top level root node of our final AST */

void yyerror(const char *s);
int sym_type(string);
void foundtoken(const char *s, const char *p);
%}

/* Represents the many different ways we can access our data */
%union {
    std::string *str;
    int token;
    Node *node;
    NBlock *block;
    NExpression *expr;
    NString *nstr;
    NStatement *stmt;
    NIdentifier *ident;
    NVariableDeclaration *var_decl;
    std::vector<NVariableDeclaration*> *varvec;
    std::vector<NExpression*> *exprvec;
}

/* Terminal symbols */
%token<str>     IDENTIFIER I_CONSTANT F_CONSTANT STRING_LITERAL
%token<str>     TYPEDEF_NAME
%token<token>   LEFT_OP RIGHT_OP LE_OP GE_OP EQ_OP NE_OP
%token<token>   AND_OP OR_OP MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN
%token<token>   SUB_ASSIGN LEFT_ASSIGN RIGHT_ASSIGN AND_ASSIGN
%token<token>   XOR_ASSIGN OR_ASSIGN

%token<token>   TYPEDEF EXTERN STATIC INCLUDE
%token<token>   CONST ORDER ABILCMD REGION
%token<token>   BOOL CHAR INT FIXED UNIT UNITGROUP POINT VOID STRING
%token<token>   STRUCT UNION STRUCT_OR_UNION_SPECIFIER

%token<token>   IF ELSE WHILE CONTINUE BREAK RETURN

/*%token<block>   block_item_list */
%type<token>    unary_operator assignment_operator binary_operator type_specifier
%type<ident>    identifier
%type<expr>     constant string include_directive
%type<expr>     primary_expression binary_expression
%type<expr>     postfix_expression unary_expression assignment_expression
%type<expr>     expression constant_expression
%type<stmt>     statement compound_statement expression_statement
%type<stmt>     selection_statement iteration_statement jump_statement declaration
%type<exprvec>   argument_expression_list

%start program

/* Order of Precedence */
%left     ','
%right    '=' MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN SUB_ASSIGN LEFT_ASSIGN RIGHT_ASSIGN AND_ASSIGN XOR_ASSIGN OR_ASSIGN
%left     OR_OP
%left     AND_OP
%left     '|'
%left     '^'
%left     '&'
%left     EQ_OP NE_OP
%left     '<' '>' LE_OP GE_OP
%left     LEFT_OP RIGHT_OP
%left     '+' '-'
%left     '*' '/' '%'
/* %right    '+' '-' '~' '!' */


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
    ;

string
    : STRING_LITERAL { foundtoken("string", $1->c_str()); $$ = new NString(*$1); delete $1; }
    ;

postfix_expression
    : primary_expression
    | postfix_expression '[' expression ']' { $$ = new NSubscript(*$1, *$3); }
    | postfix_expression '(' ')' { $$ = new NMethodCall(*$<ident>1); }
    | postfix_expression '(' argument_expression_list ')' { $$ = new NMethodCall(*$<ident>1, *$3); }
    | postfix_expression '.' identifier { $$ = new NMemberAccess(*$1, *$3); }
    ;

argument_expression_list
    : assignment_expression { $$ = new ExpressionList(); $$->push_back($1); }
    | argument_expression_list ',' assignment_expression { $1->push_back($3); }
    ;

unary_expression
    : postfix_expression
    | unary_operator unary_expression { $$ = new NUnaryOperator($1, *$2); }
    ;

unary_operator
    : '+'
    | '-'
    | '~'
    | '!'
    ;

binary_operator
    : '*' | '/' | '%'
    | '+' | '-'
    | LEFT_OP | RIGHT_OP
    | '<' | '>' | LE_OP | GE_OP
    | EQ_OP | NE_OP
    | '&'
    | '^'
    | '|'
    | AND_OP | OR_OP
    ;

binary_expression
    : unary_expression
    | binary_expression binary_operator unary_expression { $$ = new NBinaryOperator(*$1, $2, *$3); }
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
    | TYPEDEF type_specifier identifier ';' /* this is just a simple hack */
        { type_table[$3->name] = TYPEDEF_NAME; }
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
    : EXTERN | STATIC
    ;

type_specifier
    : VOID | ABILCMD | CHAR
    | INT | FIXED | STRING
    | BOOL | UNIT | UNITGROUP
    | ORDER | POINT | REGION
    | struct_or_union_specifier {$$ = STRUCT_OR_UNION_SPECIFIER; }
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

type_qualifier
    : CONST
    ;

declarator
    : direct_declarator
    ;

direct_declarator
    : identifier
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
    : block_item /*{ $$ = new NBlock(); $$->statements.push_back($<stmt>1); } */
    | block_item_list block_item /* { $1->statements.push_back($<stmt>2); } */
    ;

block_item
    : function_definition
    | declaration
    | statement
    | include_directive
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
    : block_item_list
    ;

include_directive
    : INCLUDE string { $$ = new NIncludeDirective(*$<nstr>2); }
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

int sym_type(string str){
    if (type_table[str] != 0) return type_table[str];
    return IDENTIFIER;
}

void foundtoken(const char *s, const char *p){
    cout << linenum << ": found " << s << ": " << p << endl;
}
