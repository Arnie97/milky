#ifndef LEXER_H_INCLUDED
#define LEXER_H_INCLUDED

#define MAX_INDENTATION_LEVEL (20)

int get_token(Token *token);
void get_whitespace(Token *token, int pos_in_token);

#endif /* LEXER_H_INCLUDED */
