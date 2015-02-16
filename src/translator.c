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
    for (;;) {
        int prev_pos = line_pos;
        next_token(&token);
        printf(token.kind > 0x20?
            "line_pos..%d->%d   kind..%c    str..[%s]":
            "line_pos..%d->%d   kind..%d    str..[%s]",
            prev_pos, line_pos, token.kind, token.str);
        getchar();
    }
}
