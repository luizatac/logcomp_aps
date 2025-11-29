%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern FILE *outf;
extern int yylineno;
void yyerror(const char *s);
int yylex(void);

/* rótulos para gerar jump targets */
static int label_counter = 0;
char *new_label() {
    char *buf = malloc(32);
    if (!buf) { perror("malloc"); exit(1); }
    sprintf(buf, "L%d", label_counter++);
    return buf;
}

/* pilha para rótulos de while (suporta aninhamento) */
#define MAX_LOOP_DEPTH 256
static char *loop_start_stack[MAX_LOOP_DEPTH];
static char *loop_end_stack[MAX_LOOP_DEPTH];
static int loop_depth = 0;
%}

/* Garantir que a definição de Cond apareça no header (.h) gerado pelo Bison,
   para que parking.l (que inclui parking.tab.h) saiba o tipo. */
%code requires {
typedef struct {
    int op;   /* 1 = GT, 2 = LT, 3 = EQ */
    int val;
} Cond;
}

/* tipos semânticos */
%union {
    int ival;
    Cond *cond;
}

/* tokens */
%token VAGAS ENTRADA SAIDA ALARME ENQUANTO PARAR
%token LBRACE RBRACE
%token GT LT EQ
%token GE LE

%token <ival> NUMBER
%type <cond> condicao

%%

programa:
    /* vazio */
  | programa stmt
  ;

stmt:
    declaracao
  | comando
  ;

/* -----------------------------
   DECLARAÇÃO DE VAGAS
   ----------------------------- */

declaracao:
    VAGAS NUMBER
    {
        /* Na MicrowaveVM usamos o registrador TIME para representar o número de vagas disponíveis. */
        fprintf(outf, "SET TIME %d\n", $2);
    }
  ;

/* -----------------------------
   COMANDOS
   ----------------------------- */

comando:
    /* entrada N : decrementa TIME N vezes (até zero), usando POWER como contador */
    ENTRADA NUMBER
    {
        if ($2 > 0) {
            char *Lloop = new_label();
            char *Lend  = new_label();

            fprintf(outf, "SET POWER %d\n", $2);
            fprintf(outf, "%s:\n", Lloop);
            /* DECJZ POWER Lend  -> se POWER == 0 pula para Lend; senão, POWER-- e continua */
            fprintf(outf, "DECJZ POWER %s\n", Lend);
            /* DECJZ TIME Lloop  -> se TIME == 0 não decrementa e volta para o início;
                                   senão TIME-- e segue para GOTO */
            fprintf(outf, "DECJZ TIME %s\n", Lloop);
            fprintf(outf, "GOTO %s\n", Lloop);
            fprintf(outf, "%s:\n", Lend);

            free(Lloop);
            free(Lend);
        }
        /* entrada 0: não gera código (no-op) */
    }
  /* saida N : incrementa TIME N vezes, usando POWER como contador */
  | SAIDA NUMBER
    {
        if ($2 > 0) {
            char *Lloop = new_label();
            char *Lend  = new_label();

            fprintf(outf, "SET POWER %d\n", $2);
            fprintf(outf, "%s:\n", Lloop);
            fprintf(outf, "DECJZ POWER %s\n", Lend);
            fprintf(outf, "INC TIME\n");
            fprintf(outf, "GOTO %s\n", Lloop);
            fprintf(outf, "%s:\n", Lend);

            free(Lloop);
            free(Lend);
        }
        /* saida 0: no-op */
    }
  /* alarme : imprime o valor de TIME */
  | ALARME
    {
        fprintf(outf, "PRINT\n");
    }
  /* enquanto vagas > 0 { bloco } */
  | ENQUANTO condicao LBRACE
    {
        Cond *c = $2;

        /* Implementação da APS: só aceitamos 'enquanto vagas > 0' */
        if (!(c->op == 1 && c->val == 0)) {
            fprintf(stderr,
                    "Erro: implementação atual suporta apenas 'enquanto vagas > 0'.\n");
            exit(1);
        }

        if (loop_depth >= MAX_LOOP_DEPTH) {
            fprintf(stderr, "Ninho de loops muito profundo\n");
            exit(1);
        }

        /* gerar rótulos e empilhar */
        char *Lstart = new_label();
        char *Lend   = new_label();
        loop_start_stack[loop_depth] = Lstart;
        loop_end_stack[loop_depth] = Lend;
        loop_depth++;

        /* Início do loop: testa TIME (vagas) > 0
           DECJZ TIME Lend -> se TIME == 0, sai do loop (TIME não é alterado).
           Caso contrário, TIME-- e depois restauramos com INC TIME. */
        fprintf(outf, "%s:\n", Lstart);
        fprintf(outf, "DECJZ TIME %s\n", Lend);
        fprintf(outf, "INC TIME\n");

        free(c);
    }
    bloco RBRACE
    {
        /* ação executada *após* o bloco: fechar o loop usando rótulos da pilha */
        if (loop_depth <= 0) {
            fprintf(stderr, "Erro interno: loop_depth inconsistente\n");
            exit(1);
        }
        loop_depth--;
        char *Lstart = loop_start_stack[loop_depth];
        char *Lend   = loop_end_stack[loop_depth];

        /* salto de volta e rótulo de fim */
        fprintf(outf, "GOTO %s\n", Lstart);
        fprintf(outf, "%s:\n", Lend);

        free(Lstart);
        free(Lend);
    }
  /* parar : termina o programa */
  | PARAR
    {
        fprintf(outf, "HALT\n");
    }
  ;

bloco:
    /* vazio */
  | bloco comando
  ;

/* -----------------------------
   CONDIÇÃO DE ENQUANTO
   (mantemos GT, LT, EQ na gramática,
    mas a implementação só usa GT 0)
   ----------------------------- */

condicao:
    VAGAS GT NUMBER
    {
        Cond *c = malloc(sizeof(Cond));
        if (!c) { perror("malloc"); exit(1); }
        c->op = 1;
        c->val = $3;
        $$ = c;
    }
  | VAGAS LT NUMBER
    {
        Cond *c = malloc(sizeof(Cond));
        if (!c) { perror("malloc"); exit(1); }
        c->op = 2;
        c->val = $3;
        $$ = c;
    }
  | VAGAS EQ NUMBER
    {
        Cond *c = malloc(sizeof(Cond));
        if (!c) { perror("malloc"); exit(1); }
        c->op = 3;
        c->val = $3;
        $$ = c;
    }
  ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Erro sintático na linha %d: %s\n", yylineno, s);
}
