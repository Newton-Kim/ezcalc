%{
#include "procstack.h"
#include "io/ecio.h"
#include "math/ecmath.h"
#include <ezvm/ezvm.h>
#include <iostream>
#include <functional>
#include <cstddef>
#include <cstdint>
#include <cstring>

#define YYDEBUG 1
#define USE_EQUALITY_API

int yylex();
void yyerror (char const *s);

using namespace std;
static ezVM s_vm;
static ProcStack s_proc_stack;
static bool s_prompt = false;
static size_t s_count = 0;
static bool s_do_dump = false;

#define EZC_ENTRY "main"
#define EZC_STDOUT "stdout"
#define EZC_STDERR "stderr"
#define EZC_POW "pow"
#define EZC_MAX_RETURN_VALUES 16

#ifndef USE_EQUALITY_API
static void compare(ezAddress result, ezAddress larg, ezAddress rarg, function<void(ezAsmProcedure* proc, ezAddress, string label)> func) {
	ezAsmProcedure* proc = s_proc_stack.func();
	ecBlockIf blk(s_count++);
	ezAddress vt(EZ_ASM_SEGMENT_CONSTANT, s_vm.assembler().constant(true)), vf(EZ_ASM_SEGMENT_CONSTANT, s_vm.assembler().constant(false));
	ezAddress cond(EZ_ASM_SEGMENT_LOCAL, s_proc_stack.inc_temp());
	proc->cmp(cond, larg, rarg);
	func(proc, cond, blk.label_else());
	proc->mv(result, vt);
	proc->bra(blk.label_end());
	proc->label(blk.label_else());
	proc->mv(result, vf);
	proc->label(blk.label_end());
}
#endif //USE_EQUALITY_API

%}

%token STRING INTEGER FLOAT COMPLEX BOOLEAN SYMBOL EOL BATATA FUNC QUESTION
%token CMD_PRINT CMD_ERROR CMD_QUIT CMD_DUMP
%token TK_CALL TK_DO TK_WHILE TK_UNTIL TK_IF TK_ELIF TK_ELSE TK_FOR TK_END TK_GE TK_LE TK_NE TK_EQ TK_AND TK_OR TK_XOR TK_RETURN

%type <s_value> SYMBOL STRING
%type <i_value> INTEGER
%type <b_value> BOOLEAN
%type <f_value> FLOAT COMPLEX
%type <a_value> logical_or_expr logical_and_expr var primary_expr unary_expr exponential_expr multiplicative_expr additive_expr relational_expr equality_expr and_expr xor_expr or_expr

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

%right '=' TK_POW
%%
program : %empty | program proc | program code {
		if(s_prompt) {
			s_proc_stack.clear();
			s_vm.run();
			if(s_do_dump) {
				s_vm.dump().dump("stdout");
				s_do_dump = false;
			}
			s_vm.assembler().reset(EZC_ENTRY);
			ezAsmProcedure* proc = s_vm.assembler().new_proc(EZC_ENTRY, -1, -1);
			s_proc_stack.push(proc);
			cout << "> ";
		}
	};

proc : FUNC SYMBOL '(' {
		ezAsmProcedure* proc = s_vm.assembler().new_proc($2, -1, -1);
		s_proc_stack.push(proc);
		s_proc_stack.addrs().push(vector<ezAddress>());
		s_proc_stack.args().push(vector<ezAddress>());
	} args ')' {
		ezAsmProcedure* proc = s_proc_stack.func();
		proc->args(s_proc_stack.args().top().size());
		free($2);
	}  codes TK_END EOL {
		s_proc_stack.addrs().pop();
		s_proc_stack.args().pop();
		s_proc_stack.pop();
	};

codes : code | codes code;

code : EOL | line EOL {s_proc_stack.reset_temp();};

line : assignment
	| print
	| err
	| call
	| dump
	| do_while
	| for
	| if
	| return
	| quit;

return : TK_RETURN {
		s_proc_stack.args().push(vector<ezAddress>());
	} exprs {
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		instr->ret(s_proc_stack.args().top());
		s_proc_stack.args().pop();
	}

for : TK_FOR '(' assignment ';' logical_or_expr ';' assignment ')' codes TK_END

do_while : TK_DO {
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		ecBlockDoWhile* blk = new ecBlockDoWhile(s_count++);
		proc->label(blk->label_begin(), instr->size());
		s_proc_stack.blocks().push(blk);
	} codes  TK_WHILE '(' logical_or_expr ')' {
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		ecBlock* blk = s_proc_stack.blocks().top();
		if(blk->type != EC_BLOCK_TYPE_DO_WHILE) throw runtime_error("do-while loop is incompleted");
		ezAddress cond(EZ_ASM_SEGMENT_LOCAL, s_proc_stack.inc_temp());
		instr->cmp(cond, ezAddress(EZ_ASM_SEGMENT_CONSTANT, s_vm.assembler().constant(true)), ezAddress($6.segment, $6.offset));
		instr->beq(cond, proc->label2index(((ecBlockDoWhile*)blk)->label_begin()));
		proc->label(((ecBlockDoWhile*)blk)->label_end(), instr->size());
		delete blk;
		s_proc_stack.blocks().pop();
	} 
	| TK_WHILE{
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		ecBlockDoWhile* blk = new ecBlockDoWhile(s_count++);
		s_proc_stack.blocks().push(blk);
		proc->label(blk->label_begin(), instr->size());
	} '(' logical_or_expr ')' {
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		ecBlock* blk = s_proc_stack.blocks().top();
		if(blk->type != EC_BLOCK_TYPE_DO_WHILE) throw runtime_error("do-while loop is incompleted");
		ezAddress cond(EZ_ASM_SEGMENT_LOCAL, s_proc_stack.inc_temp());
		instr->cmp(cond, ezAddress(EZ_ASM_SEGMENT_CONSTANT, s_vm.assembler().constant(true)), ezAddress($4.segment, $4.offset));
		instr->bne(cond, proc->label2index(((ecBlockDoWhile*)blk)->label_end()));
	} codes TK_END {
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		ecBlock* blk = s_proc_stack.blocks().top();
		if(blk->type != EC_BLOCK_TYPE_DO_WHILE) throw runtime_error("do-while loop is incompleted");
		instr->bra(proc->label2index(((ecBlockDoWhile*)blk)->label_begin()));
		proc->label(((ecBlockDoWhile*)blk)->label_end(), instr->size());
		delete blk;
		s_proc_stack.blocks().pop();
	};

if : TK_IF {
		ezAsmProcedure* proc = s_proc_stack.func();
		ecBlockIf* blk = new ecBlockIf(s_count++);
		s_proc_stack.blocks().push(blk);
	} '(' logical_or_expr ')' {
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		ecBlock* blk = s_proc_stack.blocks().top();
		if(blk->type != EC_BLOCK_TYPE_IF) throw runtime_error("if statement is incompleted");
		ezAddress cond(EZ_ASM_SEGMENT_LOCAL, s_proc_stack.inc_temp());
		instr->cmp(cond, ezAddress(EZ_ASM_SEGMENT_CONSTANT, s_vm.assembler().constant(true)), ezAddress($4.segment, $4.offset));
		instr->bne(cond, proc->label2index(((ecBlockIf*)blk)->label_else()));
	} codes {
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		ecBlock* blk = s_proc_stack.blocks().top();
		if(blk->type != EC_BLOCK_TYPE_IF) throw runtime_error("if statement is incompleted");
		instr->bra(proc->label2index(((ecBlockDoWhile*)blk)->label_end()));
	} TK_ELSE {
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		ecBlock* blk = s_proc_stack.blocks().top();
		if(blk->type != EC_BLOCK_TYPE_IF) throw runtime_error("if statement is incompleted");
		proc->label(((ecBlockIf*)blk)->label_else(), instr->size());
	} codes TK_END {
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		ecBlock* blk = s_proc_stack.blocks().top();
		if(blk->type != EC_BLOCK_TYPE_IF) throw runtime_error("if statement is incompleted");
		proc->label(((ecBlockIf*)blk)->label_end(), instr->size());
	};

quit : CMD_QUIT EOL {exit(0);};

assignment : {s_proc_stack.addrs().push(vector<ezAddress>()); }
	vars '=' {s_proc_stack.args().push(vector<ezAddress>());}
	exprs {
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		instr->mv(s_proc_stack.addrs().top(), s_proc_stack.args().top());
		s_proc_stack.addrs().pop();
		s_proc_stack.args().pop();
	};

print : cmd_print {
		s_proc_stack.addrs().push(vector<ezAddress>());
		s_proc_stack.args().push(vector<ezAddress>());
	} exprs {
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		ezAddress func(EZ_ASM_SEGMENT_GLOBAL, s_vm.assembler().global(EZC_STDOUT)); 
		instr->call(func, s_proc_stack.args().top(), s_proc_stack.addrs().top());
		s_proc_stack.addrs().pop();
		s_proc_stack.args().pop();
	};

cmd_print : CMD_PRINT | QUESTION;

err : CMD_ERROR {
		s_proc_stack.addrs().push(vector<ezAddress>());
		s_proc_stack.args().push(vector<ezAddress>());
	} exprs {
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		ezAddress func(EZ_ASM_SEGMENT_GLOBAL, s_vm.assembler().global(EZC_STDERR)); 
		instr->call(func, s_proc_stack.args().top(), s_proc_stack.addrs().top());
		s_proc_stack.addrs().pop();
		s_proc_stack.args().pop();
	};

call : TK_CALL SYMBOL {
		s_proc_stack.args().push(vector<ezAddress>());
		s_proc_stack.addrs().push(vector<ezAddress>());
	} args {
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		ezAddress func(EZ_ASM_SEGMENT_GLOBAL, s_vm.assembler().global($2)); 
		instr->call(func, s_proc_stack.args().top(), s_proc_stack.addrs().top());
		s_proc_stack.args().pop();
		s_proc_stack.addrs().pop();
		free($2);
	};

dump : CMD_DUMP {s_do_dump = true;}

args : %empty | exprs

vars : var {s_proc_stack.addrs().top().push_back(ezAddress($1.segment, $1.offset));}
	| vars ',' var {s_proc_stack.addrs().top().push_back(ezAddress($3.segment, $3.offset));};

var : SYMBOL {
		if(s_proc_stack.is_entry() || s_vm.assembler().is_global($1)) {
			$$.segment = EZ_ASM_SEGMENT_GLOBAL;
			$$.offset = s_vm.assembler().global($1);
		} else {
			ezAsmProcedure* proc = s_proc_stack.func();
			$$.segment = EZ_ASM_SEGMENT_LOCAL;
			$$.offset = proc->local($1);
			s_proc_stack.set_local($$.offset);
		}
		free($1);
	};

exprs : logical_or_expr {s_proc_stack.args().top().push_back(ezAddress($1.segment, $1.offset));}
	| exprs ',' logical_or_expr {s_proc_stack.args().top().push_back(ezAddress($3.segment, $3.offset));}
	| SYMBOL {
		s_proc_stack.args().push(vector<ezAddress>());
		s_proc_stack.addrs().push(vector<ezAddress>());
		for(size_t i = 0 ; i < EZC_MAX_RETURN_VALUES ; i++) 
			s_proc_stack.addrs().top().push_back(ezAddress(EZ_ASM_SEGMENT_LOCAL, s_proc_stack.inc_temp()));
	} '(' args ')' {
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAddress func(EZ_ASM_SEGMENT_GLOBAL, s_vm.assembler().global($1)); 
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		instr->call(func, s_proc_stack.args().top(), s_proc_stack.addrs().top());
		s_proc_stack.args().pop();
		vector<ezAddress>& addr = s_proc_stack.addrs().top();
		for(size_t i = 0 ; i < addr.size() ; i++)
			s_proc_stack.args().top().push_back(addr[i]);
		s_proc_stack.addrs().pop();
	};

primary_expr : INTEGER { $$.segment = EZ_ASM_SEGMENT_CONSTANT; $$.offset = s_vm.assembler().constant($1); }
	| FLOAT { $$.segment = EZ_ASM_SEGMENT_CONSTANT; $$.offset = s_vm.assembler().constant($1); }
	| COMPLEX { $$.segment = EZ_ASM_SEGMENT_CONSTANT; $$.offset = s_vm.assembler().constant(complex<double>(0,$1)); }
	| STRING { $$.segment = EZ_ASM_SEGMENT_CONSTANT; $$.offset = s_vm.assembler().constant($1); }
	| BOOLEAN { $$.segment = EZ_ASM_SEGMENT_CONSTANT; $$.offset = s_vm.assembler().constant($1); }
	| SYMBOL {
		s_proc_stack.args().push(vector<ezAddress>());
		s_proc_stack.addrs().push(vector<ezAddress>());
	} '(' args ')' {
		$$.segment = EZ_ASM_SEGMENT_LOCAL;
		$$.offset = s_proc_stack.inc_temp();
		s_proc_stack.addrs().top().push_back(ezAddress($$.segment, $$.offset));
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		ezAddress func(EZ_ASM_SEGMENT_GLOBAL, s_vm.assembler().global($1)); 
		instr->call(func, s_proc_stack.args().top(), s_proc_stack.addrs().top());
		s_proc_stack.args().pop();
		s_proc_stack.addrs().pop();
	}
	| var {$$ = $1;}
	| '(' logical_or_expr ')' {$$ = $2;};

unary_expr : primary_expr {$$ = $1;}
	| '-' primary_expr %prec BATATA {
		$$.segment = EZ_ASM_SEGMENT_LOCAL;
		$$.offset = s_proc_stack.inc_temp();
		ezAsmProcedure* func = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		instr->neg(ezAddress($$.segment, $$.offset), ezAddress($2.segment, $2.offset));
	};
exponential_expr : unary_expr {$$=$1;}
	| unary_expr TK_POW unary_expr {
		$$.segment = EZ_ASM_SEGMENT_LOCAL;
		$$.offset = s_proc_stack.inc_temp();
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		ezAddress func(EZ_ASM_SEGMENT_GLOBAL, s_vm.assembler().global(EZC_POW)); 
		s_proc_stack.args().push(vector<ezAddress>());
		s_proc_stack.addrs().push(vector<ezAddress>());
		s_proc_stack.args().top().push_back(ezAddress($1.segment, $1.offset));
		s_proc_stack.args().top().push_back(ezAddress($3.segment, $3.offset));
		s_proc_stack.addrs().top().push_back(ezAddress($$.segment, $$.offset));
		instr->call(func, s_proc_stack.args().top(), s_proc_stack.addrs().top());
		s_proc_stack.args().pop();
		s_proc_stack.addrs().pop();
	};

multiplicative_expr : exponential_expr { $$ = $1; }
	| multiplicative_expr '*' exponential_expr {
		$$.segment = EZ_ASM_SEGMENT_LOCAL;
		$$.offset = s_proc_stack.inc_temp();
		ezAsmProcedure* func = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		ezAddress lparam($1.segment, $1.offset), rparam($3.segment, $3.offset);
		instr->mul(ezAddress ($$.segment, $$.offset), lparam, rparam);
	}
	| multiplicative_expr '/' exponential_expr {
		$$.segment = EZ_ASM_SEGMENT_LOCAL;
		$$.offset = s_proc_stack.inc_temp();
		ezAsmProcedure* func = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		ezAddress lparam($1.segment, $1.offset), rparam($3.segment, $3.offset);
		instr->div(ezAddress ($$.segment, $$.offset), lparam, rparam);
	}
	| multiplicative_expr '%' exponential_expr {
		$$.segment = EZ_ASM_SEGMENT_LOCAL;
		$$.offset = s_proc_stack.inc_temp();
		ezAsmProcedure* func = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		ezAddress lparam($1.segment, $1.offset), rparam($3.segment, $3.offset);
		instr->mod(ezAddress ($$.segment, $$.offset), lparam, rparam);
	};

additive_expr : multiplicative_expr { $$ = $1; }
	| additive_expr '+' multiplicative_expr {
		$$.segment = EZ_ASM_SEGMENT_LOCAL;
		$$.offset = s_proc_stack.inc_temp();
		ezAsmProcedure* func = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		ezAddress lparam($1.segment, $1.offset), rparam($3.segment, $3.offset);
		instr->add(ezAddress ($$.segment, $$.offset), lparam, rparam);
	}
	| additive_expr '-' multiplicative_expr {
		$$.segment = EZ_ASM_SEGMENT_LOCAL;
		$$.offset = s_proc_stack.inc_temp();
		ezAsmProcedure* func = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		ezAddress lparam($1.segment, $1.offset), rparam($3.segment, $3.offset);
		instr->sub(ezAddress ($$.segment, $$.offset), lparam, rparam);
	};

relational_expr : additive_expr { $$ = $1; }
	| relational_expr '>' additive_expr {
		$$.segment = EZ_ASM_SEGMENT_LOCAL;
		$$.offset = s_proc_stack.inc_temp();
		ezAddress tf($$.segment, $$.offset);
#ifdef USE_EQUALITY_API
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		instr->tlt(tf, ezAddress($3.segment, $3.offset), ezAddress($1.segment, $1.offset)); 
#else //USE_EQUALITY_API
		compare(tf, ezAddress($3.segment, $3.offset), ezAddress($1.segment, $1.offset),
			[&](ezAsmProcedure* proc, ezAddress cond, string label){ proc->bge(cond, label); }
		);
#endif //USE_EQUALITY_API
	}
	| relational_expr '<' additive_expr {
		$$.segment = EZ_ASM_SEGMENT_LOCAL;
		$$.offset = s_proc_stack.inc_temp();
		ezAddress tf($$.segment, $$.offset);
#ifdef USE_EQUALITY_API
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		instr->tlt(tf, ezAddress($1.segment, $1.offset), ezAddress($3.segment, $3.offset)); 
#else //USE_EQUALITY_API
		compare(tf, ezAddress($1.segment, $1.offset), ezAddress($3.segment, $3.offset),
			[&](ezAsmProcedure* proc, ezAddress cond, string label){ proc->bge(cond, label); }
		);
#endif //USE_EQUALITY_API
	}
	| relational_expr TK_GE additive_expr {
		$$.segment = EZ_ASM_SEGMENT_LOCAL;
		$$.offset = s_proc_stack.inc_temp();
		ezAddress tf($$.segment, $$.offset);
#ifdef USE_EQUALITY_API
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		instr->tge(tf, ezAddress($1.segment, $1.offset), ezAddress($3.segment, $3.offset)); 
#else //USE_EQUALITY_API
		compare(tf, ezAddress($1.segment, $1.offset), ezAddress($3.segment, $3.offset),
			[&](ezAsmProcedure* proc, ezAddress cond, string label){ proc->blt(cond, label); }
		);
#endif //USE_EQUALITY_API
	}
	| relational_expr TK_LE additive_expr {
		$$.segment = EZ_ASM_SEGMENT_LOCAL;
		$$.offset = s_proc_stack.inc_temp();
		ezAddress tf($$.segment, $$.offset);
#ifdef USE_EQUALITY_API
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		instr->tge(tf, ezAddress($3.segment, $3.offset), ezAddress($1.segment, $1.offset)); 
#else //USE_EQUALITY_API
		compare(tf, ezAddress($3.segment, $3.offset), ezAddress($1.segment, $1.offset),
			[&](ezAsmProcedure* proc, ezAddress cond, string label){ proc->blt(cond, label); }
		);
#endif //USE_EQUALITY_API
	};

equality_expr : relational_expr {$$=$1;}
	| equality_expr TK_NE relational_expr {
		$$.segment = EZ_ASM_SEGMENT_LOCAL;
		$$.offset = s_proc_stack.inc_temp();
		ezAddress tf($$.segment, $$.offset);
#ifdef USE_EQUALITY_API
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		instr->tne(tf, ezAddress($1.segment, $1.offset), ezAddress($3.segment, $3.offset)); 
#else //USE_EQUALITY_API
		compare(tf, ezAddress($1.segment, $1.offset), ezAddress($3.segment, $3.offset),
			[&](ezAsmProcedure* proc, ezAddress cond, string label){ proc->beq(cond, label); }
		);
#endif //USE_EQUALITY_API
	}
	| equality_expr TK_EQ relational_expr {
		$$.segment = EZ_ASM_SEGMENT_LOCAL;
		$$.offset = s_proc_stack.inc_temp();
		ezAddress tf($$.segment, $$.offset);
#ifdef USE_EQUALITY_API
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		instr->teq(tf, ezAddress($1.segment, $1.offset), ezAddress($3.segment, $3.offset)); 
#else //USE_EQUALITY_API
		compare(tf, ezAddress($1.segment, $1.offset), ezAddress($3.segment, $3.offset),
			[&](ezAsmProcedure* proc, ezAddress cond, string label){ proc->bne(cond, label); }
		);
#endif //USE_EQUALITY_API
	};

and_expr : equality_expr {$$=$1;}
	| and_expr '&' equality_expr {
		$$.segment = EZ_ASM_SEGMENT_LOCAL;
		$$.offset = s_proc_stack.inc_temp();
		ezAsmProcedure* func = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		ezAddress lparam($1.segment, $1.offset), rparam($3.segment, $3.offset);
		instr->bitwise_and(ezAddress ($$.segment, $$.offset), lparam, rparam);
	};

xor_expr : and_expr {$$=$1;}
	| xor_expr '^' and_expr {
		$$.segment = EZ_ASM_SEGMENT_LOCAL;
		$$.offset = s_proc_stack.inc_temp();
		ezAsmProcedure* func = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		ezAddress lparam($1.segment, $1.offset), rparam($3.segment, $3.offset);
		instr->bitwise_xor(ezAddress ($$.segment, $$.offset), lparam, rparam);
	}

or_expr : xor_expr {$$=$1;}
	| or_expr '|' xor_expr {
		$$.segment = EZ_ASM_SEGMENT_LOCAL;
		$$.offset = s_proc_stack.inc_temp();
		ezAsmProcedure* func = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		ezAddress lparam($1.segment, $1.offset), rparam($3.segment, $3.offset);
		instr->bitwise_or(ezAddress ($$.segment, $$.offset), lparam, rparam);
	};

logical_and_expr : or_expr {$$=$1;}
	| logical_and_expr {
		ecBlockIf* blk = new ecBlockIf(s_count++);
		s_proc_stack.blocks().push(blk);
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		ezAddress cond(EZ_ASM_SEGMENT_LOCAL, s_proc_stack.inc_temp());
		instr->cmp(cond, ezAddress($1.segment, $1.offset), ezAddress(EZ_ASM_SEGMENT_CONSTANT, s_vm.assembler().constant(true)));
		instr->bne(cond, proc->label2index(blk->label_else()));
	} TK_AND or_expr {
		$$.segment = EZ_ASM_SEGMENT_LOCAL;
		$$.offset = s_proc_stack.inc_temp();
		ezAddress cond(EZ_ASM_SEGMENT_LOCAL, s_proc_stack.inc_temp());
		ecBlock* blk = s_proc_stack.blocks().top();
		if(blk->type != EC_BLOCK_TYPE_IF) throw runtime_error("block mismatch");
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		ezAddress result($$.segment, $$.offset), rarg($4.segment, $4.offset), vf(EZ_ASM_SEGMENT_CONSTANT, s_vm.assembler().constant(false));
		instr->mv(result, rarg);
		instr->bra(proc->label2index(((ecBlockIf*)blk)->label_end()));
		proc->label(((ecBlockIf*)blk)->label_else(), instr->size());
		instr->mv(result, vf);
		proc->label(((ecBlockIf*)blk)->label_end(), instr->size());
		s_proc_stack.blocks().pop();
		delete blk;
	};

logical_or_expr : logical_and_expr {$$=$1;}
	| logical_or_expr {
		ecBlockIf* blk = new ecBlockIf(s_count++);
		s_proc_stack.blocks().push(blk);
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		ezAddress cond(EZ_ASM_SEGMENT_LOCAL, s_proc_stack.inc_temp());
		instr->cmp(cond, ezAddress($1.segment, $1.offset), ezAddress(EZ_ASM_SEGMENT_CONSTANT, s_vm.assembler().constant(true)));
		instr->beq(cond, proc->label2index(blk->label_else()));
	} TK_OR or_expr {
		$$.segment = EZ_ASM_SEGMENT_LOCAL;
		$$.offset = s_proc_stack.inc_temp();
		ezAddress cond(EZ_ASM_SEGMENT_LOCAL, s_proc_stack.inc_temp());
		ecBlock* blk = s_proc_stack.blocks().top();
		if(blk->type != EC_BLOCK_TYPE_IF) throw runtime_error("block mismatch");
		ezAsmProcedure* proc = s_proc_stack.func();
		ezAsmInstruction* instr = s_proc_stack.instr().top();
		ezAddress result($$.segment, $$.offset), rarg($4.segment, $4.offset), vt(EZ_ASM_SEGMENT_CONSTANT, s_vm.assembler().constant(true));
		instr->mv(result, rarg);
		instr->bra(proc->label2index(((ecBlockIf*)blk)->label_end()));
		proc->label(((ecBlockIf*)blk)->label_else(), instr->size());
		instr->mv(result, vt);
		proc->label(((ecBlockIf*)blk)->label_end(), instr->size());
		s_proc_stack.blocks().pop();
		delete blk;
	}
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
  ezAsmProcedure* proc = s_vm.assembler().new_proc(EZC_ENTRY, -1, -1);
  proc->mems(256);
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
  ezAsmProcedure* proc = s_vm.assembler().new_proc(EZC_ENTRY, -1, -1);
  proc->mems(256);
  s_proc_stack.push(proc);
  yyparse();
  s_proc_stack.clear();
  if(s_do_dump) {
    s_vm.dump().dump("stdout");
    s_do_dump = false;
  }
  s_vm.run();
}

void yyerror (char const *s) {
	extern int yylineno;
	cout << "error (" << yylineno << "): " << s << endl;
}
