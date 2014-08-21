#include <iostream>
#include <vector>
#include <string>

class Node;
    class NExpression; //<expr> numeric expr <exprvec> call_args
        class NInteger;
        class NFixed;
        class NString;
        class NIdentifier; //<ident> ident
        class NMethodCall;
        class NBinaryOperator;
        class NUnaryOperator;
        class NAssignment;
        class NBlock;       //<stmt> program stmts block
        class NSubscript;
        class NMemberAccess;
        class NIncludeDirective;
    class NStatement;   //<stmt> stmt var_decl func_decl
        class NExpressionStatement;
        class NVariableDeclaration; //<varvec> func_decl_args
        class NFunctionDeclaration;

typedef std::vector<NStatement*> StatementList;
typedef std::vector<NExpression*> ExpressionList;
typedef std::vector<NVariableDeclaration*> VariableList;

using namespace std;

class Node {
public:
    virtual ~Node() {}
};

class NExpression : public Node { };

class NStatement : public Node { };

class NInteger : public NExpression {
public:
    int value;
    NInteger(int value) : value(value) { }
};

class NFixed : public NExpression {
public:
    double value;
    NFixed(double value) : value(value) { }
};

class NString : public NExpression {
public:
    string value;
    NString(string value) : value(value) { }
};

class NIdentifier : public NExpression {
public:
    std::string name;
    NIdentifier(const std::string& name) : name(name) { }
};

class NMethodCall : public NExpression {
public:
    const NIdentifier& id;
    ExpressionList arguments;
    NMethodCall(const NIdentifier& id, ExpressionList& arguments) :
        id(id), arguments(arguments) { }
    NMethodCall(const NIdentifier& id) : id(id) { }
};

class NBinaryOperator : public NExpression {
public:
    int op;
    NExpression& lhs;
    NExpression& rhs;
    NBinaryOperator(NExpression& lhs, int op, NExpression& rhs) :
        lhs(lhs), rhs(rhs), op(op) { }
};

class NUnaryOperator : public NExpression {
public:
    int op;
    NExpression& rhs;
    NUnaryOperator(int op, NExpression& rhs) :
        rhs(rhs), op(op) { }
};

class NAssignment : public NExpression {
public:
    NIdentifier& lhs;
    NExpression& rhs;
    NAssignment(NIdentifier& lhs, NExpression& rhs) : 
        lhs(lhs), rhs(rhs) { }
};

class NSubscript : public NExpression {
public:
    NExpression& lhs;
    NExpression& rhs;
    NSubscript(NExpression& lhs, NExpression& rhs) : 
        lhs(lhs), rhs(rhs) { }
};

class NMemberAccess : public NExpression {
public:
    NExpression& lhs;
    NIdentifier& rhs;
    NMemberAccess(NExpression& lhs, NIdentifier& rhs) : 
        lhs(lhs), rhs(rhs) { }
};

class NIncludeDirective : public NExpression {
public:
    NString& file;
    NIncludeDirective(NString& file) : file(file) { }
};

class NBlock : public NExpression {
public:
    StatementList statements;
    NBlock() { }
};

class NExpressionStatement : public NStatement {
public:
    NExpression& expression;
    NExpressionStatement(NExpression& expression) : 
        expression(expression) { }
};

class NVariableDeclaration : public NStatement {
public:
    const NIdentifier& type;
    NIdentifier& id;
    NExpression *assignmentExpr;
    NVariableDeclaration(const NIdentifier& type, NIdentifier& id) :
        type(type), id(id) { }
    NVariableDeclaration(const NIdentifier& type, NIdentifier& id, NExpression *assignmentExpr) :
        type(type), id(id), assignmentExpr(assignmentExpr) { }
};

class NFunctionDeclaration : public NStatement {
public:
    const NIdentifier& type;
    const NIdentifier& id;
    VariableList arguments;
    NBlock& block;
    NFunctionDeclaration(const NIdentifier& type, const NIdentifier& id, 
            const VariableList& arguments, NBlock& block) :
        type(type), id(id), arguments(arguments), block(block) { }
};
