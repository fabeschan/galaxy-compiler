#include <iostream>
#include <vector>
#include <string>
#include <sstream>
#include "yyltype.hpp"

#ifndef AST_HPP
#define AST_HPP

class Node;
    class NExpression; //<expr> numeric expr <exprvec> call_args
        class NInteger;
        class NFixed;
        class NString;
        class NIdentifier; //<ident> ident
        class NMethodCall;
        class NBinaryOperator;
        class NUnaryOperator;
        class NBlock;       //<stmt> program stmts block
        class NSubscript;
        class NMemberAccess;
        class NIncludeDirective;
        class NExpressionList;
    class NStatement;   //<stmt> stmt var_decl func_decl
        class NExpressionStatement;
        class NVariableDeclaration; //<varvec> func_decl_args
        class NFunctionDeclaration;
        class NSelectionStatement;

typedef std::vector<NStatement*> StatementList;
typedef std::vector<NExpression*> ExpressionList;
typedef std::vector<NVariableDeclaration*> VariableList;

using namespace std;

class Node {
public:
    virtual ~Node() {}
    virtual string to_string() { return ""; }
    virtual const char* c_str() {return this->to_string().c_str(); }
};

class NExpression : public Node {
public:
    YYLTYPE* yylloc;
    void save_location(YYLTYPE loc){ yylloc = new YYLTYPE(loc); }
    NExpression() : yylloc(NULL) { }
};

class NStatement : public Node { };

class NInteger : public NExpression {
public:
    int value;
    NInteger(int value) : value(value) { }
    string to_string(){ return std::to_string(value); }
};

class NFixed : public NExpression {
public:
    double value;
    NFixed(double value) : value(value) { }
    string to_string(){ return std::to_string(value); }
};

class NString : public NExpression {
public:
    string value;
    NString(string value) : value(value) { }
    string to_string(){ return value; }
};

class NIdentifier : public NExpression {
public:
    std::string name;
    NIdentifier(const std::string& name) : name(name) { }
    string to_string(){ return name; }
};

class NMethodCall : public NExpression {
public:
    NExpression* expr;
    ExpressionList* arguments;
    NMethodCall(NExpression* expr, ExpressionList* arguments) :
        expr(expr), arguments(arguments) {
        if (!arguments) arguments = new ExpressionList();
    }
    string to_string(){
        stringstream ss;
        ss << expr->to_string() << "(" << arguments << ")";
        return ss.str();
    }
};

class NBinaryOperator : public NExpression {
public:
    int op;
    NExpression* lhs;
    NExpression* rhs;
    NBinaryOperator(NExpression* lhs, int op, NExpression* rhs) :
        lhs(lhs), rhs(rhs), op(op) { }
    string to_string(){
        stringstream ss;
        string s;
        s += op;
        ss << lhs->to_string() << s << rhs->to_string();
        return ss.str();
    }
};

class NUnaryOperator : public NExpression {
public:
    int op;
    NExpression* rhs;
    NUnaryOperator(int op, NExpression* rhs) :
        rhs(rhs), op(op) { }
    string to_string(){
        stringstream ss;
        string s;
        s += op;
        ss << s << rhs->to_string();
        return ss.str();
    }
};

class NExpressionList : public NExpression {
public:
    ExpressionList* list;
    NExpressionList(ExpressionList* list) : list(list) { }
    string to_string(){
        stringstream ss;
        for (ExpressionList::iterator it = list->begin(); it != list->end(); it++){
            ss << (*it)->to_string() << ", ";
        }
        string s = ss.str();
        return s.substr(0, s.length() - 2);
    }
};

class NSubscript : public NExpression {
public:
    NExpression* lhs;
    ExpressionList* rhs;
    NSubscript(NExpression* lhs, ExpressionList* rhs) : 
        lhs(lhs), rhs(rhs) { }
    string to_string(){
        stringstream ss;
        NExpressionList rhs_ = NExpressionList(rhs);
        ss << lhs->to_string() << "[" << rhs_.to_string()<< "]";
        return ss.str();
    }
};

class NMemberAccess : public NExpression {
public:
    NExpression* lhs;
    NIdentifier* rhs;
    NMemberAccess(NExpression* lhs, NIdentifier* rhs) : 
        lhs(lhs), rhs(rhs) { }
    string to_string(){
        stringstream ss;
        ss << lhs->to_string() << "." << rhs->to_string();
        return ss.str();
    }
};

class NIncludeDirective : public NExpression {
public:
    NString* file;
    NIncludeDirective(NString* file) : file(file) { }
    string to_string(){
        stringstream ss;
        ss << "include " << file->to_string();
        return ss.str();
    }
};

class NBlock : public NExpression {
public:
    StatementList statements;
    NBlock() { }
};

class NSelectionStatement : public NStatement {
public:
    ExpressionList* condition;
    int op; // IF or WHILE
    NStatement* thenStmt;
    NStatement* elseStmt;
    NSelectionStatement(int op, ExpressionList* condition, NStatement* thenStmt, NStatement* elseStmt) : 
        op(op), condition(condition), thenStmt(thenStmt), elseStmt(elseStmt) { }
    string to_string(){
        stringstream ss;
        NExpressionList cond = NExpressionList(condition);
        ss << cond.to_string();
        return ss.str();
    }
};

class NExpressionStatement : public NStatement {
public:
    NExpression* expression;
    NExpressionStatement(NExpression* expression) : 
        expression(expression) { }
};

class NVariableDeclaration : public NStatement {
public:
    const NIdentifier* type;
    NIdentifier* id;
    NExpression *assignmentExpr;
    NVariableDeclaration(const NIdentifier* type, NIdentifier* id) :
        type(type), id(id) { }
    NVariableDeclaration(const NIdentifier* type, NIdentifier* id, NExpression *assignmentExpr) :
        type(type), id(id), assignmentExpr(assignmentExpr) { }
};

class NFunctionDeclaration : public NStatement {
public:
    const NIdentifier* type;
    const NIdentifier* id;
    VariableList* arguments;
    NBlock* block;
    NFunctionDeclaration(const NIdentifier* type, const NIdentifier* id, 
            VariableList* arguments, NBlock* block) :
        type(type), id(id), arguments(arguments), block(block) { }
};

#endif
