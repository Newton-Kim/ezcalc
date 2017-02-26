%{
#include <stdlib.h>
#include <string.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include "parse.hh"
// fp {[0-9]+\.|\.[0-9]+|[0-9]+\.[0-9]+}{[EDed][+-]?[0-9]+[\.]?|\.[0-9]+|[0-9]+\.[0-9]+}?
%}

%option yylineno
digit [0-9]+
fraction {digit}\.|\.{digit}|{digit}\.{digit}
exponent {digit}|{digit}\.|\.{digit}|{digit}\.{digit}
fp {fraction}|{exponent}[eE][+-]?{exponent}
complex {fp}j|{digit}j
%%
{digit} { yylval.i_value = strtol(yytext, NULL, 10); return INTEGER;}
{fp} { yylval.f_value = strtof(yytext, NULL); return FLOAT;}
{complex} { yytext[strlen(yytext) - 1] = 0; yylval.f_value = strtof(yytext, NULL); return COMPLEX;}
[-+*/%=\^] return *yytext;
[\n\r] return EOL;
"?"    return QUESTION;
"print" {return CMD_PRINT;}
"error" {return CMD_ERROR;}
"func" {return FUNC;}
"dump" {return CMD_DUMP;}
"quit" {return CMD_QUIT;}
[_a-zA-Z][_a-zA-Z0-9]* { yylval.s_value = strdup(yytext); return SYMBOL;}
"("|")"|"," {return *yytext;}
#.* {}
[ \t] {}
\"[^"]*\" { yylval.s_value = strndup(yytext + 1, strlen(yytext) - 2); return STRING;}
%%
