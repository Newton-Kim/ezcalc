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
static string s_label;
static size_t s_count = 0;
static bool s_negative = false;

#define EZC_ENTRY "main"
#define EZC_STDOUT "stdout"
#define EZC_STDERR "stderr"
#define EZC_POW "pow"
#define EZC_MAX_RETURN_VALUES 16
%}

%token STRING INTEGER FLOAT COMPLEX BOOLEAN SYMBOL EOL BATATA FUNC QUESTION
%token CMD_PRINT CMD_ERROR CMD_QUIT CMD_DUMP
%token TK_DO TK_WHILE TK_UNTIL TK_IF TK_ELIF TK_ELSE TK_FOR TK_END TK_GE TK_LE TK_NE TK_EQ TK_AND TK_OR TK_XOR

%type <s_value> SYMBOL STRING
%type <i_value> INTEGER
%type <b_value> BOOLEAN
%type <f_value> FLOAT COMPLEX
%type <a_value> expr var

%union {
	bool b_value;
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

proc : FUNC SYMBOL '(' {s_proc_stack.args().push(vector<ezAddress>());} args ')' { free($2); }  codes TK_END EOL { s_proc_stack.args().pop(); };

codes : code | codes code;

code : EOL | line EOL {s_proc_stack.reset_temp();};

line : assignment
	| print
	| err
	| dump
	| do_while
	| for
	| if
	| quit;

for : TK_FOR '(' assignment ';' lexpr ';' assignment ')' codes TK_END

do_while : TK_DO {
		ezAsmProcedure* proc = s_proc_stack.func();
		ecBlockDoWhile* blk = new ecBlockDoWhile(s_count++);
		proc->label(blk->begin());
		s_proc_stack.blocks().push(blk);
	} codes  TK_WHILE {
		ecBlock* blk = s_proc_stack.blocks().top();
		if(blk->type != EC_BLOCK_TYPE_DO_WHILE) throw runtime_error("do-while loop is incompleted");
		s_label = ((ecBlockDoWhile*)blk)->begin();
		s_negative = false;
	} '(' lexpr ')' {
		ezAsmProcedure* proc = s_proc_stack.func();
		ecBlock* blk = s_proc_stack.blocks().top();
		if(blk->type != EC_BLOCK_TYPE_DO_WHILE) throw runtime_error("do-while loop is incompleted");
		proc->label(((ecBlockDoWhile*)blk)->end());
		delete blk;
		s_proc_stack.blocks().pop();
		s_label.clear();
	} 
	| TK_WHILE{
		ezAsmProcedure* proc = s_proc_stack.func();
		ecBlockDoWhile* blk = new ecBlockDoWhile(s_count++);
		proc->label(blk->begin());
		s_proc_stack.blocks().push(blk);
		s_label = blk->end();
		s_negative = true;
	} '(' lexpr ')' codes TK_END {
		ezAsmProcedure* proc = s_proc_stack.func();
		ecBlock* blk = s_proc_stack.blocks().top();
		if(blk->type != EC_BLOCK_TYPE_DO_WHILE) throw runtime_error("do-while loop is incompleted");
		proc->bra(((ecBlockDoWhile*)blk)->begin());
		proc->label(((ecBlockDoWhile*)blk)->end());
		delete blk;
		s_proc_stack.blocks().pop();
		s_label.clear();
	};

if : TK_IF '(' lexpr ')' codes elif TK_ELSE codes TK_END;

elif : %empty | elif TK_ELIF '(' lexpr ')' codes;

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
	| BOOLEAN { $$.segment = EZ_ASM_SEGMENT_CONSTANT; $$.offset = s_vm.assembler().constant($1); }
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
	| expr TK_AND expr {
		$$.segment = EZ_ASM_SEGMENT_LOCAL;
		$$.offset = s_proc_stack.inc_temp();
		ezAsmProcedure* func = s_proc_stack.func();
		ezAddress lparam($1.segment, $1.offset), rparam($3.segment, $3.offset);
		func->bitwise_and(ezAddress ($$.segment, $$.offset), lparam, rparam);
	}
	| expr TK_OR expr {
		$$.segment = EZ_ASM_SEGMENT_LOCAL;
		$$.offset = s_proc_stack.inc_temp();
		ezAsmProcedure* func = s_proc_stack.func();
		ezAddress lparam($1.segment, $1.offset), rparam($3.segment, $3.offset);
		func->bitwise_or(ezAddress ($$.segment, $$.offset), lparam, rparam);
	}
	| expr TK_XOR expr {
		$$.segment = EZ_ASM_SEGMENT_LOCAL;
		$$.offset = s_proc_stack.inc_temp();
		ezAsmProcedure* func = s_proc_stack.func();
		ezAddress lparam($1.segment, $1.offset), rparam($3.segment, $3.offset);
		func->bitwise_or(ezAddress ($$.segment, $$.offset), lparam, rparam);
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
	| '-' expr %prec BATATA {
		$$.segment = EZ_ASM_SEGMENT_LOCAL;
		$$.offset = s_proc_stack.inc_temp();
		ezAsmProcedure* func = s_proc_stack.func();
		func->neg(ezAddress($$.segment, $$.offset), ezAddress($2.segment, $2.offset));
	}
	| '(' expr ')' {$$ = $2;};

lexpr : expr '>' expr {
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAddress cond(EZ_ASM_SEGMENT_LOCAL, s_proc_stack.inc_temp());
		proc->cmp(cond, ezAddress($3.segment, $3.offset), ezAddress($1.segment, $1.offset));
		if(s_negative)
			proc->bge(cond, s_label);
		else
			proc->blt(cond, s_label);
	}
	| expr '<' expr {
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAddress cond(EZ_ASM_SEGMENT_LOCAL, s_proc_stack.inc_temp());
		proc->cmp(cond, ezAddress($1.segment, $1.offset), ezAddress($3.segment, $3.offset));
		if(s_negative)
			proc->bge(cond, s_label);
		else
			proc->blt(cond, s_label);
	}
	| expr TK_GE expr {
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAddress cond(EZ_ASM_SEGMENT_LOCAL, s_proc_stack.inc_temp());
		proc->cmp(cond, ezAddress($1.segment, $1.offset), ezAddress($3.segment, $3.offset));
		if(s_negative)
			proc->blt(cond, s_label);
		else
			proc->bge(cond, s_label);
	}
	| expr TK_LE expr {
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAddress cond(EZ_ASM_SEGMENT_LOCAL, s_proc_stack.inc_temp());
		proc->cmp(cond, ezAddress($3.segment, $3.offset), ezAddress($1.segment, $1.offset));
		if(s_negative)
			proc->blt(cond, s_label);
		else
			proc->bge(cond, s_label);
	}
	| expr TK_NE expr {
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAddress cond(EZ_ASM_SEGMENT_LOCAL, s_proc_stack.inc_temp());
		proc->cmp(cond, ezAddress($1.segment, $1.offset), ezAddress($3.segment, $3.offset));
		if(s_negative)
			proc->beq(cond, s_label);
		else
			proc->bne(cond, s_label);
	}
	| expr TK_EQ expr {
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAddress cond(EZ_ASM_SEGMENT_LOCAL, s_proc_stack.inc_temp());
		proc->cmp(cond, ezAddress($1.segment, $1.offset), ezAddress($3.segment, $3.offset));
		if(s_negative)
			proc->bne(cond, s_label);
		else
			proc->beq(cond, s_label);
	}
	| lexpr TK_AND lexpr {
	}
	| lexpr TK_OR lexpr {
	}
	| lexpr TK_XOR lexpr {
	}
	| '(' lexpr ')' {};
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
