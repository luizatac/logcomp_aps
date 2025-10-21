%{
#include "parking.tab.h"
#include <stdio.h>
#include <stdlib.h>

extern FILE *outf;
extern int yylineno;
%}

/* opções: não gerar yywrap e acompanhar número de linhas */
%option noyywrap yylineno

DIGIT   [0-9]+

%%

"vagas"             { return VAGAS; }
"entrada"           { return ENTRADA; }
"saida"             { return SAIDA; }
"alarme"            { return ALARME; }
"enquanto"          { return ENQUANTO; }
"parar"             { return PARAR; }

"=="                { return EQ; }
">="                { return GE; }
"<="                { return LE; }
">"                 { return GT; }
"<"                 { return LT; }

"{"                 { return LBRACE; }
"}"                 { return RBRACE; }

{DIGIT}             { yylval.ival = atoi(yytext); return NUMBER; }

[ \t\r\n]+          { /* ignora espaços e quebras de linha */ }

"//".*               { /* comentário de linha */ }

.                   {
                        fprintf(stderr, "Caractere inesperado na linha %d: '%s'\n", yylineno, yytext);
                        exit(1);
                    }

%%
