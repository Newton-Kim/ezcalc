%{
#include <ezvm/ezvm.h>
#include <iostream>
#define YYDEBUG 1

int yylex();
void yyerror (char const *s);

using namespace std;
static ezVM* s_vm = NULL;
static bool is_over = false;
static stack<ezAsmProcedure*> s_proc_stack;
static vector<ezAddress> s_args;
static vector<ezAddress> s_addrs;

#define EZC_ENTRY "_main"
#define EZC_PRINT "_print"
%}

%token INTEGER FLOAT SYMBOL EOL BATATA FUNC
%token CMD_PRINT CMD_QUIT

%type <s_value> SYMBOL
%type <i_value> INTEGER
%type <f_value> FLOAT
%type <a_value> expr var

%union {
	int i_value;
	double f_value;
	char* s_value;
	struct {
		size_t segment;
		size_t offset;
	} a_value;
};

%start program

%right '='
%left '+' '-'
%left '*' '/' '%'
%%
program : %empty | program proc | program code { s_vm->run(); cout << "> ";};

proc : FUNC SYMBOL '(' args ')' '{' codes '}' EOL;

codes : %empty | codes code;

code : EOL | line EOL;

line : assignment
	| print
	| quit;

quit : CMD_QUIT EOL {exit(0);};

assignment : vars '=' exprs;

print : CMD_PRINT exprs {
		ezAsmProcedure* proc = s_proc_stack.top();
		ezAddress func(EZ_ASM_SEGMENT_GLOBAL, s_vm->assembler().global(EZC_PRINT)); 
		proc->call(func, s_args, s_addrs);
	};

args : %empty | args ',' SYMBOL;

vars : var | vars ',' var;

var : SYMBOL { $$.segment = EZ_ASM_SEGMENT_GLOBAL; $$.offset = s_vm->assembler().global($1); };

exprs : expr {s_args.push_back(ezAddress($1.segment, $1.offset));}
	| exprs ',' expr {s_args.push_back(ezAddress($3.segment, $3.offset));};

expr : INTEGER { $$.segment = EZ_ASM_SEGMENT_CONSTANT; $$.offset = s_vm->assembler().constant($1); }
	| FLOAT { $$.segment = EZ_ASM_SEGMENT_CONSTANT; $$.offset = s_vm->assembler().constant($1); }
	| var {$$ = $1;}
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
  s_vm = &vm;
  s_vm->assembler().entry(EZC_ENTRY);
  ezAsmProcedure* proc = s_vm->assembler().new_proc(EZC_ENTRY, 0, 0, 256, -1, -1);
  s_proc_stack.push(proc);
  cout << "> ";
  yyparse();
}

void yyerror (char const *s) {
	extern int yylineno;
	cout << "error (" << yylineno << "): " << s << endl;
}
