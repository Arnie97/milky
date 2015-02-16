#ifndef TRANSLATOR_H_INCLUDED
#define TRANSLATOR_H_INCLUDED

#include <stdio.h>

#define MAX_LOOK_AHEAD_TOKENS (20)

void parse_file(void);
void next_token(Token *token);
void drop_token(Token *token);

#endif /* TRANSLATOR_H_INCLUDED */
