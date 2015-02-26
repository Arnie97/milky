#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "input.h"
#include "token.h"
#include "indent.h"
#include "translator.h"

void
parse_file(void)
{
    Token token;
    TranslatorStatus status = INITIAL_STATUS;
    IndentStatus pending = FUNCTION, captured[MAX_INDENT_LEVELS] = { 0 };
    char captured_count = 0;

    dputs("start!");
    look_ahead_queue(INIT);
    do {
        int prev_pos = line_pos;
        get_indent(&token);
        switch (token.kind) {
        case BAD_TOKEN:
            fprintf(stderr, "Unhandled token: %s", token.str);
            exit(8);
        case SHARP_TOKEN:
            if (status == BEGIN_OF_LINE) {
                status = PREPROCESSOR;
            }
            break;
        case INDENT_TOKEN:
            if (status != BEFORE_INDENT) {
                fprintf(stderr, "Unexpected indent.\n");
                exit(10);
            }
            status = INITIAL_STATUS;
            switch (pending) {
            case IF:
                putchar(')');
                putchar('{');
            }
            captured[captured_count++] = pending;
            pending = FUNCTION;
            continue;
        case UNINDENT_TOKEN:
            switch (captured[--captured_count]) {
            case IF:
                putchar('}');
                break;
            case ELSE:
                break;
            case SWITCH:
                putchar(')');
                putchar('{');
                break;
            case CASE:
                break;
            case FALLTHROUGH:
                break;
            case REPEAT:
                printf("} while (%s);", "cond");
                break;
            case STRUCT:
                break;
            }
            continue;
        case KEYWORD_TOKEN:
            switch (token.type) {
            case 4: // do
                fprintf(stderr, "Illegal keyword \"do\".\n");
                exit(4);
            case 0: case 2: case 3: case 5: // if (cond) { statement }
                status = AFTER_KEYWORD;
                pending = IF;
                strcat(token.str, "(");
                break;
            case 12: case 13: case 14: // typedef struct { list } name;
                status = BEFORE_COLON;
                pending = STRUCT;
                break;
            case 7: // switch (foo) { statement }
                status = BEFORE_COLON;
                pending = SWITCH;
                strcat(token.str, "(");
                break;
            case 1: case 8: case 9: // else { statement }
                status = BEFORE_COLON;
                pending = ELSE;
                break;
            case 6: // repeat;
                pending = REPEAT;
                break;
            case 10: // fallthrough;
                if (pending == CASE) {
                    pending = FALLTHROUGH;
                }
                break;
            case 11: // pass;
                putchar(';');
                continue;
            }
            break;
        case COLON_TOKEN:
            switch (status) {
            case AFTER_KEYWORD:
                fprintf(stderr, "Expected conditions before colon.\n");
                exit(11);
            case BEFORE_COLON:
                status = BEFORE_INDENT;
                token.str[0] = ' ';
                break;
            default:
                fprintf(stderr, "Unexpected colons.\n");
                exit(12);
            }
            break;
        case LINE_COMMENT_TOKEN:
        case BLOCK_COMMENT_TOKEN:
            break;
        case MULTILINE_COMMENT_TOKEN:
        case END_OF_LINE_TOKEN:
            if (status == BEFORE_INDENT) {
                fprintf(stderr, "Expected indent.\n");
                exit(13);
            } else if (status != PREPROCESSOR) {
                // putchar(';');
            }
            status = BEGIN_OF_LINE;
            break;
        default:
            switch (status) {
            case AFTER_KEYWORD:
                status = BEFORE_COLON;
                break;
            case BEFORE_INDENT:
                status = INLINE_STATEMENT;
                break;
            case BEGIN_OF_LINE:
                status = INITIAL_STATUS;
            }
        }
        dprintf((token.kind > 0x20?
            "look_ahead..%d(%d,%d)->%d  kind..%c  status..%d  str..[%s]":
            "look_ahead..%d(%d,%d)->%d  kind..%d  status..%d  str..[%s]",
            prev_pos, token.row, token.column, line_pos, token.kind, status, token.str));
        fputs(token.str, stdout);
    } while (token.kind != SCOPE_TOKEN);
    look_ahead_queue(DESTROY);
}
