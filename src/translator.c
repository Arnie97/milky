#include "milky.h"
#include "token.h"
#include "indent.h"
#include "translator.h"

void
parse_file(void)
{
    Token token;
    printf("start!\n");
    look_ahead_queue(INIT);
    do {
        int prev_pos = line_pos;
        get_indent(&token);
        printf(token.kind > 0x20?
            "look_ahead..%d(%d,%d)->%d  kind..%c  str..[%s]":
            "look_ahead..%d(%d,%d)->%d  kind..%d  str..[%s]",
            prev_pos, token.row, token.column, line_pos, token.kind, token.str);
        getchar();
    } while (token.kind != SCOPE_TOKEN);
    look_ahead_queue(DESTROY);
}
