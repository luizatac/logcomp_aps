/* src/main.c (corrigido) */
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <errno.h>

FILE *outf = NULL;
int yyparse(void);
extern FILE *yyin;
int yylex(void);

/* yylineno é definido pelo Flex (quando %option yylineno).
   Aqui apenas declaramos que existe. */
extern int yylineno;

/* Função auxiliar para criar diretório, silenciosa se já existir */
static void ensure_outdir(const char *outdir) {
    struct stat st;
    if (stat(outdir, &st) == -1) {
        if (mkdir(outdir, 0700) != 0 && errno != EEXIST) {
            perror("mkdir");
            /* não fatal: o arquivo de saída pode falhar depois */
        }
    }
}

int main(int argc, char **argv) {
    if (argc < 3) {
        fprintf(stderr, "Uso: %s <entrada.ps> <saida.asm>\n", argv[0]);
        return 1;
    }

    yyin = fopen(argv[1], "r");
    if (!yyin) { perror("fopen entrada"); return 1; }

    ensure_outdir("out");

    outf = fopen(argv[2], "w");
    if (!outf) { perror("fopen saida"); return 1; }

    if (yyparse() == 0) {
        printf("Parse OK — saída em %s\n", argv[2]);
    } else {
        printf("Parse falhou\n");
    }

    fclose(yyin);
    fclose(outf);
    return 0;
}
