%{
#include "minic.tab.h"
#include <string.h>
#include <stdlib.h>
int yylineno = 1;
%}

%%

"//".*                { }

int                    { return INT; }
float                  { return FLOAT; }
char                   { return CHAR; }
if                     { return IF; }
else                   { return ELSE; }
while                  { return WHILE; }
for                    { return FOR; }

[a-zA-Z_][a-zA-Z0-9_]* { yylval.str = strdup(yytext); return ID; }
[0-9]+                 { yylval.str = strdup(yytext); return NUM; }

"<="                   { return RELOP; }
">="                   { return RELOP; }
"=="                   { return RELOP; }
"!="                   { return RELOP; }
"<"                    { return RELOP; }
">"                    { return RELOP; }

"&&"                   { return AND; }
"||"                   { return OR; }

"="                    { return '='; }
"!"                    { return '!'; }
"+"                    { return '+'; }
"-"                    { return '-'; }
"*"                    { return '*'; }
"/"                    { return '/'; }

";"                    { return ';'; }
","                    { return ','; }
"("                    { return '('; }
")"                    { return ')'; }
"{"                    { return '{'; }
"}"                    { return '}'; }
"["                    { return '['; }
"]"                    { return ']'; }

[ \t\r]+               { }
\n                     { yylineno++; }

.                      {
                          fprintf(stderr,
                          "Unknown character '%s' at line %d\n",
                          yytext, yylineno);
                       }

%%

int yywrap(void) { return 1; }
