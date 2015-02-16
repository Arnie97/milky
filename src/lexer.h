#ifndef LEXER_H_INCLUDED
#define LEXER_H_INCLUDED

#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>

#define MAX_INDENTATION_LEVEL (20)

int get_token(Token *token);
void get_whitespace(Token *token, int pos_in_token);

#endif /* LEXER_H_INCLUDED */
