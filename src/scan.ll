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
[-+*/%=\^\{\}<>,()&|] return *yytext;
"<=" return TK_LE;
">=" return TK_GE;
"!=" return TK_NE;
"==" return TK_EQ;
"&&" return TK_AND;
"||" return TK_OR;
"**" return TK_POW;
"call" return TK_CALL;
"true" { yylval.b_value = true; return BOOLEAN;}
"false" { yylval.b_value = false; return BOOLEAN;}
"end" return TK_END;
"if" return TK_IF;
"else" return TK_ELSE;
"elif" return TK_ELIF;
"for" return TK_ELIF;
[\n\r] return EOL;
"?"    return QUESTION;
"print" {return CMD_PRINT;}
"error" {return CMD_ERROR;}
"func" {return FUNC;}
"dump" {return CMD_DUMP;}
"quit" {return CMD_QUIT;}
"do"   {return TK_DO;}
"while"   {return TK_WHILE;}
"until"   {return TK_UNTIL;}
"return"   {return TK_RETURN;}
[_a-zA-Z][_a-zA-Z0-9]* { yylval.s_value = strdup(yytext); return SYMBOL;}
#.* {}
[ \t] {}
\"[^"]*\" { yylval.s_value = strndup(yytext + 1, strlen(yytext) - 2); return STRING;}
%%
