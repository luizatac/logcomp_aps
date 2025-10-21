CC = gcc
FLEX = flex
BISON = bison

SRC = src

all: parking_parser

parking_parser: parking.tab.c lex.yy.c main.c
	$(CC) parking.tab.c lex.yy.c main.c -lfl -o parking_parser

parking.tab.c parking.tab.h: $(SRC)/parking.y
	$(BISON) -d $(SRC)/parking.y -o parking.tab.c

lex.yy.c: $(SRC)/parking.l parking.tab.h
	$(FLEX) -o lex.yy.c $(SRC)/parking.l

main.c: $(SRC)/main.c
	cp $(SRC)/main.c .

clean:
	rm -f parking.tab.c parking.tab.h lex.yy.c parking_parser *.o
