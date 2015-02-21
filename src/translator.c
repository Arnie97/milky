#include "milky.h"
#include "token.h"
#include "lexer.h"
#include "translator.h"

static Token *look_ahead_tokens[MAX_LOOK_AHEAD_TOKENS];
static int tokens_available;

void
next_token(Token *token)
{
    if (tokens_available) {
        token = look_ahead_tokens[tokens_available--];
    } else {
        get_whitespace(token, get_token(token));
    }
}

void
drop_token(Token *token)
{
    if (tokens_available >= MAX_LOOK_AHEAD_TOKENS) {
        fprintf(stderr, "Too much look-ahead tokens.");
        exit(7);
    }
    look_ahead_tokens[tokens_available++] = token;
}

void
parse_file(void)
{
    Token token;
    printf("start!\n");
    do {
        int prev_pos = line_pos;
        next_token(&token);
        printf(token.kind > 0x20?
            "look_ahead..%d(%d,%d)->%d  kind..%c  str..[%s]":
            "look_ahead..%d(%d,%d)->%d  kind..%d  str..[%s]",
            prev_pos, token.row, token.column, line_pos, token.kind, token.str);
        getchar();
    } while (token.kind != SCOPE_TOKEN);
}
