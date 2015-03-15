#include <stdio.h>

#include "input.h"
#include "token.h"
#include "indent.h"
#include "translator.h"

#define NONEXISTENT (0xFF)

static Token look_ahead_token;

void
next_token(Token *token)
{
    if (look_ahead_token->type == NONEXISTENT) {
        dprintf(("fwd >"));
        get_indent(token);
    } else {
        dprintf(("pop >"));
        *token = look_ahead_token;
        look_ahead_token->type = NONEXISTENT;
    }
}

void
store_token(Token *token)
{
    dprintf(("push> "));
    look_ahead_token = *token;
}

void
parse_file(void)
{
    Token token;
    dputs("start!");
    look_ahead_queue(INIT);
    do {
        int prev_pos = line_pos;
        next_token(&token);
        dprintf((token.kind > 0x20?
            "look_ahead..%d(%d,%d)->%d  kind..%c  str..[%s]":
            "look_ahead..%d(%d,%d)->%d  kind..%d  str..[%s]",
            prev_pos, token.row, token.column, line_pos, token.kind, token.str));
        getchar();
    } while (token.kind != SCOPE_TOKEN);
    look_ahead_queue(DESTROY);
}
