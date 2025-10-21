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

declaracao:
    VAGAS NUMBER
    {
        fprintf(outf, "SET_CAPACITY %d\n", $2);
    }
  ;

comando:
    ENTRADA NUMBER
    {
        fprintf(outf, "IN %d\n", $2);
    }
  | SAIDA NUMBER
    {
        fprintf(outf, "OUT %d\n", $2);
    }
  | ALARME
    {
        fprintf(outf, "ALARM\n");
    }
  /* ENQUANTO: usamos mid-rule actions para emitir labels antes do bloco */
  | ENQUANTO condicao LBRACE
    {
        /* ação executada *antes* de reduzir o bloco */
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

        /* emitir rótulo de início e instrução de pulo condicional para fora do loop
           (note: a lógica vem de $2, que é Cond*) */
        fprintf(outf, "%s:\n", Lstart);
        if ($2->op == 1) {
            /* VAGAS > val  -> if VAGAS <= val goto Lend */
            fprintf(outf, "IF VAGAS <= %d GOTO %s\n", $2->val, Lend);
        } else if ($2->op == 2) {
            /* VAGAS < val -> if VAGAS >= val goto Lend */
            fprintf(outf, "IF VAGAS >= %d GOTO %s\n", $2->val, Lend);
        } else if ($2->op == 3) {
            /* VAGAS == val -> if VAGAS != val goto Lend */
            fprintf(outf, "IF VAGAS != %d GOTO %s\n", $2->val, Lend);
        }
        free($2);
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
  | PARAR
    {
        fprintf(outf, "HALT\n");
    }
  ;

bloco:
    /* vazio */
  | bloco comando
  ;

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
