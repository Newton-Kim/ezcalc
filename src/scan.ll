%{
%}

%option yylineno

%%
[0-9]+ { yylval.i = strtol(yytext, NULL, 10); return INTEGER;}
[0-9]+\.[EDed][+-][0-9]+ { yylval.f = strtof(yytext, NULL, 10); return FLOAT;}
\.[0-9]+[EDed][+-][0-9]+ { yylval.f = strtof(yytext, NULL, 10); return FLOAT;}
[0-9]+\.[0-9]+[EDed][+-][0-9]+ { yylval.f = strtof(yytext, NULL, 10); return FLOAT;}
[+-*/%=^]
[\n\r] return EOL;
[_a-zA-Z][_a-zA-Z0-9]* { yylval.s = strdup(string); return VAR;}
%%