.PHONY: default clean test

CC=gcc
CC_FLAGS?=-Wall -O3 -std=c99
CC_CMD:=$(CC) $(CC_FLAGS)
MILKYC?=milky

default: test

clean:
	rm -rf `find ./ -name '*.o' -print`
	rm -rf `find ./ -name '*.exe' -print`

test: milky
	./milky

milky: lexer.c token.h
	$(CC_CMD) -o milky lexer.c
