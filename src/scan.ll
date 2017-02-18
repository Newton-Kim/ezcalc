%{
#include <stdlib.h>
#include <string.h>
#include <stddef.h>
#include <stdint.h>
#include "parse.hh"
%}

%option yylineno

%%
[0-9]+ { yylval.i_value = strtol(yytext, NULL, 10); return INTEGER;}
[0-9]+\.[EDed][+-][0-9]+ { yylval.f_value = strtof(yytext, NULL); return FLOAT;}
\.[0-9]+[EDed][+-][0-9]+ { yylval.f_value = strtof(yytext, NULL); return FLOAT;}
[0-9]+\.[0-9]+[EDed][+-][0-9]+ { yylval.f_value = strtof(yytext, NULL); return FLOAT;}
[-+*/%=\^] return *yytext;
[\n\r] return EOL;
"?"    return QUESTION;
"print" {return CMD_PRINT;}
"error" {return CMD_ERROR;}
"func" {return FUNC;}
"dump" {return CMD_DUMP;}
"quit" {return CMD_QUIT;}
[_a-zA-Z][_a-zA-Z0-9]* { yylval.s_value = strdup(yytext); return SYMBOL;}
%%
