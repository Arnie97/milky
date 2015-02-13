.PHONY: default build clean test

CC=gcc
CC_FLAGS?=-Wall -Wpedantic -Wno-switch -O3 -std=c99
CC_CMD:=$(CC) $(CC_FLAGS)
MILKYC?=milky

default: test

clean:
	rm -rf `find ./ -name '*.o' -print`
	rm -rf `find ./ -name '*.exe' -print`

test: build
	./milky foobar.milk

build: milky

milky: main.o lexer.o translator.o
	$(CC) -o milky main.o lexer.o translator.o

main.o: main.c milky.h translator.h main.h
	$(CC_CMD) -c main.c

lexer.o: lexer.c milky.h token.h lexer.h
	$(CC_CMD) -c lexer.c

translator.o: translator.c milky.h token.h lexer.h translator.h
	$(CC_CMD) -c translator.c
