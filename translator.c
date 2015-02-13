#include "milky.h"
#include "token.h"
#include "lexer.h"
#include "translator.h"

void
parse_file(void)
{
    Token token;
    printf("start!\n");
    for (;;) {
        int prev_pos = line_pos;
        get_whitespace(&token, get_token(&token));
        printf(token.kind > 0x20?
            "line_pos..%d->%d   kind..%c    str..[%s]":
            "line_pos..%d->%d   kind..%d    str..[%s]",
            prev_pos, line_pos, token.kind, token.str);
        getchar();
        if (token.kind == SHARP_TOKEN) {
            break;
        }
    }
}
