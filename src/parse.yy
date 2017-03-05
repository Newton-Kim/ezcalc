%{
#include "procstack.h"
#include "io/ecio.h"
#include "math/ecmath.h"
#include <ezvm/ezvm.h>
#include <iostream>
#include <cstddef>
#include <cstdint>
#include <cstring>
#define YYDEBUG 1

int yylex();
void yyerror (char const *s);

using namespace std;
static ezVM s_vm;
static ProcStack s_proc_stack;
static bool s_prompt = false;

#define EZC_ENTRY "main"
#define EZC_STDOUT "stdout"
#define EZC_STDERR "stderr"
#define EZC_POW "pow"
#define EZC_MAX_RETURN_VALUES 16
%}

%token STRING INTEGER FLOAT COMPLEX SYMBOL EOL BATATA FUNC QUESTION
%token CMD_PRINT CMD_ERROR CMD_QUIT CMD_DUMP
%token TK_DO TK_WHILE TK_UNTIL TK_GE TK_LE TK_NE TK_EQ

%type <s_value> SYMBOL STRING
%type <i_value> INTEGER
%type <f_value> FLOAT COMPLEX
%type <a_value> expr var

%union {
	int i_value;
	double f_value;
	char* s_value;
	struct {
		uint8_t segment;
		size_t offset;
	} a_value;
};

%start program

%right '=' '^'
%left '+' '-'
%left '*' '/' '%'
%%
program : %empty | program proc | program code {
		if(s_prompt) {
			s_proc_stack.clear();
			s_vm.run();
			s_vm.assembler().reset(EZC_ENTRY);
			ezAsmProcedure* proc = s_vm.assembler().new_proc(EZC_ENTRY, 0, 0, -1, -1);
			s_proc_stack.push(proc);
			cout << "> ";
		}
	};

proc : FUNC SYMBOL '(' {s_proc_stack.args().push(vector<ezAddress>());} args ')' { free($2); } '{' codes '}' EOL { s_proc_stack.args().pop(); };

codes : code | codes code;

code : EOL | line EOL {s_proc_stack.reset_temp();};

line : assignment
	| print
	| err
	| dump
	| do_while
	| quit;

do_while : TK_DO {} codes TK_WHILE '(' expr ')' {};

quit : CMD_QUIT EOL {exit(0);};

assignment : {s_proc_stack.addrs().push(vector<ezAddress>()); }
	vars '=' {s_proc_stack.args().push(vector<ezAddress>());}
	exprs {
		ezAsmProcedure* proc = s_proc_stack.func();
		proc->mv(s_proc_stack.addrs().top(), s_proc_stack.args().top());
		s_proc_stack.addrs().pop();
		s_proc_stack.args().pop();
	};

print : cmd_print {
		s_proc_stack.addrs().push(vector<ezAddress>());
		s_proc_stack.args().push(vector<ezAddress>());
	} exprs {
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAddress func(EZ_ASM_SEGMENT_GLOBAL, s_vm.assembler().global(EZC_STDOUT)); 
		proc->call(func, s_proc_stack.args().top(), s_proc_stack.addrs().top());
		s_proc_stack.addrs().pop();
		s_proc_stack.args().pop();
	};

cmd_print : CMD_PRINT | QUESTION;

err : CMD_ERROR {
		s_proc_stack.addrs().push(vector<ezAddress>());
		s_proc_stack.args().push(vector<ezAddress>());
	} exprs {
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAddress func(EZ_ASM_SEGMENT_GLOBAL, s_vm.assembler().global(EZC_STDERR)); 
		proc->call(func, s_proc_stack.args().top(), s_proc_stack.addrs().top());
		s_proc_stack.addrs().pop();
		s_proc_stack.args().pop();
	};


dump : CMD_DUMP {s_vm.dump().dump("stdout");}

args : %empty | args ',' SYMBOL {
		s_proc_stack.args().top().push_back(ezAddress(EZ_ASM_SEGMENT_GLOBAL, s_vm.assembler().global($3)));
		free($3);
	};

vars : var {s_proc_stack.addrs().top().push_back(ezAddress($1.segment, $1.offset));}
	| vars ',' var {s_proc_stack.addrs().top().push_back(ezAddress($3.segment, $3.offset));};

var : SYMBOL {
		$$.segment = EZ_ASM_SEGMENT_GLOBAL;
		$$.offset = s_vm.assembler().global($1);
		free($1);
	};

exprs : expr {s_proc_stack.args().top().push_back(ezAddress($1.segment, $1.offset));}
	| exprs ',' expr {s_proc_stack.args().top().push_back(ezAddress($3.segment, $3.offset));}
	| SYMBOL {
		s_proc_stack.args().push(vector<ezAddress>());
		s_proc_stack.addrs().push(vector<ezAddress>());
		for(size_t i = 0 ; i < EZC_MAX_RETURN_VALUES ; i++) 
			s_proc_stack.addrs().top().push_back(ezAddress(EZ_ASM_SEGMENT_LOCAL, s_proc_stack.inc_temp()));
	} '(' exprs ')' {
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAddress func(EZ_ASM_SEGMENT_GLOBAL, s_vm.assembler().global($1)); 
		proc->call(func, s_proc_stack.args().top(), s_proc_stack.addrs().top());
		s_proc_stack.args().pop();
		vector<ezAddress>& addr = s_proc_stack.addrs().top();
		for(size_t i = 0 ; i < addr.size() ; i++)
			s_proc_stack.args().top().push_back(addr[i]);
		s_proc_stack.addrs().pop();
	};

expr : INTEGER { $$.segment = EZ_ASM_SEGMENT_CONSTANT; $$.offset = s_vm.assembler().constant($1); }
	| FLOAT { $$.segment = EZ_ASM_SEGMENT_CONSTANT; $$.offset = s_vm.assembler().constant($1); }
	| COMPLEX { $$.segment = EZ_ASM_SEGMENT_CONSTANT; $$.offset = s_vm.assembler().constant(complex<double>(0,$1)); }
	| STRING { $$.segment = EZ_ASM_SEGMENT_CONSTANT; $$.offset = s_vm.assembler().constant($1); }
	| SYMBOL {
		s_proc_stack.args().push(vector<ezAddress>());
		s_proc_stack.addrs().push(vector<ezAddress>());
	} '(' exprs ')' {
		$$.segment = EZ_ASM_SEGMENT_LOCAL;
		$$.offset = s_proc_stack.inc_temp();
		s_proc_stack.addrs().top().push_back(ezAddress($$.segment, $$.offset));
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAddress func(EZ_ASM_SEGMENT_GLOBAL, s_vm.assembler().global($1)); 
		proc->call(func, s_proc_stack.args().top(), s_proc_stack.addrs().top());
		s_proc_stack.args().pop();
		s_proc_stack.addrs().pop();
	}
	| var {$$ = $1;}
	| expr '+' expr {
		$$.segment = EZ_ASM_SEGMENT_LOCAL;
		$$.offset = s_proc_stack.inc_temp();
		ezAsmProcedure* func = s_proc_stack.func();
		ezAddress lparam($1.segment, $1.offset), rparam($3.segment, $3.offset);
		func->add(ezAddress ($$.segment, $$.offset), lparam, rparam);
	}
	| expr '-' expr {
		$$.segment = EZ_ASM_SEGMENT_LOCAL;
		$$.offset = s_proc_stack.inc_temp();
		ezAsmProcedure* func = s_proc_stack.func();
		ezAddress lparam($1.segment, $1.offset), rparam($3.segment, $3.offset);
		func->sub(ezAddress ($$.segment, $$.offset), lparam, rparam);
	}
	| expr '*' expr {
		$$.segment = EZ_ASM_SEGMENT_LOCAL;
		$$.offset = s_proc_stack.inc_temp();
		ezAsmProcedure* func = s_proc_stack.func();
		ezAddress lparam($1.segment, $1.offset), rparam($3.segment, $3.offset);
		func->mul(ezAddress ($$.segment, $$.offset), lparam, rparam);
	}
	| expr '/' expr {
		$$.segment = EZ_ASM_SEGMENT_LOCAL;
		$$.offset = s_proc_stack.inc_temp();
		ezAsmProcedure* func = s_proc_stack.func();
		ezAddress lparam($1.segment, $1.offset), rparam($3.segment, $3.offset);
		func->div(ezAddress ($$.segment, $$.offset), lparam, rparam);
	}
	| expr '%' expr {
		$$.segment = EZ_ASM_SEGMENT_LOCAL;
		$$.offset = s_proc_stack.inc_temp();
		ezAsmProcedure* func = s_proc_stack.func();
		ezAddress lparam($1.segment, $1.offset), rparam($3.segment, $3.offset);
		func->mod(ezAddress ($$.segment, $$.offset), lparam, rparam);
	}
	| expr '^' expr {
		$$.segment = EZ_ASM_SEGMENT_LOCAL;
		$$.offset = s_proc_stack.inc_temp();
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAddress func(EZ_ASM_SEGMENT_GLOBAL, s_vm.assembler().global(EZC_POW)); 
		s_proc_stack.args().push(vector<ezAddress>());
		s_proc_stack.addrs().push(vector<ezAddress>());
		s_proc_stack.args().top().push_back(ezAddress($1.segment, $1.offset));
		s_proc_stack.args().top().push_back(ezAddress($3.segment, $3.offset));
		s_proc_stack.addrs().top().push_back(ezAddress($$.segment, $$.offset));
		proc->call(func, s_proc_stack.args().top(), s_proc_stack.addrs().top());
		s_proc_stack.args().pop();
		s_proc_stack.addrs().pop();
	}
	| expr '>' expr {
	}
	| expr '<' expr {
	}
	| expr TK_GE expr {
	}
	| expr TK_LE expr {
	}
	| expr TK_NE expr {
	}
	| expr TK_EQ expr {
	}
	| '-' expr %prec BATATA {
		$$.segment = EZ_ASM_SEGMENT_LOCAL;
		$$.offset = s_proc_stack.inc_temp();
		ezAsmProcedure* func = s_proc_stack.func();
		func->neg(ezAddress($$.segment, $$.offset), ezAddress($2.segment, $2.offset));
	}
	| '(' expr ')' {$$ = $2;}
;
%%

void load_functions(void) {
	char **symtab = NULL;
	ezValue **constant = NULL;
	ecIO::load(&symtab, &constant);
	s_vm.assembler().load_intrinsics(symtab, constant);
	ecMath::load(&symtab, &constant);
	s_vm.assembler().load_intrinsics(symtab, constant);
}

void run_it(void) {
  load_functions();
  s_prompt = true;
  s_vm.assembler().entry(EZC_ENTRY);
  ezAsmProcedure* proc = s_vm.assembler().new_proc(EZC_ENTRY, 0, 256, -1, -1);
  s_proc_stack.push(proc);
  cout << "> ";
  yyparse();
}

void run_it(string source) {
  load_functions();
  extern FILE* yyin;
  s_prompt = false;
  yyin = fopen(source.c_str(), "rb");
  if(!yyin) throw runtime_error(strerror(errno));
  s_vm.assembler().entry(EZC_ENTRY);
  ezAsmProcedure* proc = s_vm.assembler().new_proc(EZC_ENTRY, 0, 256, -1, -1);
  s_proc_stack.push(proc);
  yyparse();
  s_proc_stack.clear();
  s_vm.run();
}

void yyerror (char const *s) {
	extern int yylineno;
	cout << "error (" << yylineno << "): " << s << endl;
}
