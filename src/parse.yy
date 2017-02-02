%{
#include "ezvm/ezvm.h"
#define YYDEBUG 1

int yylex();
void yyerror (char const *s);

using namespace std;
static ezVM s_vm;
static ezAsmProcedure* s_proc_current = NULL;
%}

%start program

%right '='
%left '+' '-'
%left '*' '/' '%'
%%
program : %empty | program proc | program codes;

proc : 'func' symbol '(' args ')' '{' codes '}';

codes : %empty | codes line EOL;

line : assignment
	| print;

assignment : vars '=' exprs;

print : '?' expr;

args : %empty | args ',' var;

vars : var | vars ',' var;

exprs : expr | exprs ',' expr;

expr : INTEGER
	| FLOAT
	| var
	| expr '+' expr
	| expr '-' expr
	| expr '*' expr
	| expr '/' expr
	| expr '%' expr
	| '+' expr %prec BATATA
	| '-' expr %prec BATATA
	| '(' expr ')'
	;
%%

void run_it(ezVM& vm) {
}

void yyerror (char const *s) {
	extern int yylineno;
	cout << "error (" << yylineno << "): " << s << endl;
}