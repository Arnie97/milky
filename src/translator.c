#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "input.h"
#include "token.h"
#include "indent.h"
#include "translator.h"

#define NONEXISTENT (0x7F)

static Token look_ahead_token;

static void
next_token(Token *token)
{
    if (look_ahead_token.type == NONEXISTENT) {
        dprintf(("tr_fw> "));
        get_indent(token);
    } else {
        dprintf(("tr_po> "));
        *token = look_ahead_token;
        look_ahead_token.type = NONEXISTENT;
    }
    dprintf((token->str));
}

static void
store_token(Token *token)
{
    dprintf(("tr_pu> "));
    look_ahead_token = *token;
}

void
parse_file(void)
{
    Token token;
    TranslatorStatus status;
    look_ahead_token.type = NONEXISTENT;
    look_ahead_queue(INIT);
    dputs("start!");
    for (;;) {
        token.type = NONEXISTENT;
        parse_statement(&token, &status);
    }
    look_ahead_queue(DESTROY);
}

void
parse_statement(Token *token, TranslatorStatus *status)
{
    char top_level = (token->type == NONEXISTENT)? 1: 0;
    do {
        parse_expression();
        next_token(token);
        switch (token->kind) {
        case BAD_TOKEN:
            fprintf(stderr, "Unhandled token: %s", token->str);
            exit(8);
        case INDENT_TOKEN:
            fprintf(stderr, "Unexpected indent.\n");
            exit(10);
        case UNINDENT_TOKEN:
            store_token(token);
            if (!top_level) {
                return;
            }
            break;
        case KEYWORD_TOKEN:
            switch (token->type) {
            case 4: // do
                fputs("_do", stdout);
                continue;
            case 10: // fallthrough;
                break;
            case 11: // pass;
                putchar(';');
                continue;
            default:
                parse_block(token, AFTER_KEYWORD);
            }
            break;
        case COLON_TOKEN:
            store_token(token);
            parse_block(token, BEFORE_COLON);
            continue;
        case END_OF_LINE_TOKEN:
            if (*status == PREPROCESSOR) {
                *status = INITIAL_STATUS;
            }
            /* fallthrough; */
        case MULTILINE_COMMENT_TOKEN:
            if (*status == BEFORE_INDENT) {
                fprintf(stderr, "Expected indent.\n");
                exit(13);
            } else if (*status != PREPROCESSOR) {
                putchar(';');
            }
            fputs(token->str, stdout);

            next_token(token);
            if (token->kind == SHARP_TOKEN) {
                *status = PREPROCESSOR;
            }
            store_token(token);
            continue;
        default:
            dputs("Unhandled default!");
        }
        fputs(token->str, stdout);
    } while (token->kind != SCOPE_TOKEN);
    puts("~~~~~~~~~~~~~~~~~~~~");
    exit(0);
}

void
parse_block(Token *token, TranslatorStatus status)
{
    IndentStatus pending = UNKNOWN;
    if (status == BEFORE_COLON) {
        pending = FUNCTION_BLOCK;
    } else {
        switch (token->type) {
        case 0: case 2: case 3: case 5: // if (cond) { statement }
            pending = IF_BLOCK;
            fputs(token->str, stdout);
            putchar('(');
            parse_expression();
            status = BEFORE_COLON;
            break;
        case 12: case 13: case 14: // typedef struct { list } name;
            pending = STRUCT_BLOCK;
            fputs(token->str, stdout);
            parse_expression();
            status = BEFORE_COLON;
            break;
        case 7: // switch (foo) { statement }
            pending = SWITCH_BLOCK;
            fputs(token->str, stdout);
            status = BEFORE_COLON;
            strcat(token->str, "(");
            break;
        case 8: // case 9, 7: statement
        case 9: // default: statement
            switch (pending) {
            case SWITCH_BLOCK:
            case CASE_BLOCK:
                pending = CASE_BLOCK;
                fputs(token->str, stdout);
                parse_expression();
                status = BEFORE_COLON;
                break;
            default:
                fprintf(stderr, "Unexpected keyword in this context:\n");
                fprintf(stderr, "Unexpected 'case' without 'switch'\n");
                exit(15);
            }
        case 1: // else { statement }
            pending = ELSE_BLOCK;
            fputs(token->str, stdout);
            status = BEFORE_COLON;
            break;
        case 6: // repeat;
            pending = REPEAT_BLOCK;
            fputs(token->str, stdout);
            parse_expression();
            status = BEFORE_COLON;
            break;
        default:
            dputs("Unhandled keyword!");
        }
    }

    for (;;) {
        next_token(token);
        switch (token->kind) {
        case COLON_TOKEN:
            switch (status) {
            case AFTER_KEYWORD:
                fprintf(stderr, "Expected conditions before colon.\n");
                exit(11);
            case BEFORE_COLON:
                status = BEFORE_INDENT;
                switch (pending) {
                case CASE_BLOCK:
                    break;
                case IF_BLOCK:
                    putchar(')');
                    /* fallthrough; */
                default:
                    putchar('{');
                }
                if (parse_expression()) {
                    status = INLINE_STATEMENT;
                    putchar('}');
                    return;
                }
                break;
            default:
                fprintf(stderr, "Unexpected colons.\n");
                exit(12);
            }
            continue;
        case INDENT_TOKEN:
            if (status != BEFORE_INDENT) {
                fprintf(stderr, "Unexpected indent.\n");
                exit(10);
            }
            status = BEFORE_UNINDENT;
            parse_statement(token, &status);
            continue;
        case UNINDENT_TOKEN:
            switch (pending) {
            case SWITCH_BLOCK:
                putchar(')');
                putchar('{');
                break;
            case REPEAT_BLOCK:
            case STRUCT_BLOCK:
                printf("} while (%s);", "cond");
                break;
            case FUNCTION_BLOCK:
            case IF_BLOCK:
            case ELSE_BLOCK:
                putchar('}');
                break;
            default:
                break;
            }
            return;
        default:
            dputs("Executed to the end of parse_block!");
            getchar();
        }
    }
}

int
parse_expression(void)
{
    int token_count = 0;
    Token token;
    for (;;) {
        next_token(&token);
        switch (token.kind) {
        case BAD_TOKEN:
            dputs("BADBAD");
        case INDENT_TOKEN:
        case UNINDENT_TOKEN:
        case KEYWORD_TOKEN:
        case COLON_TOKEN:
        case MULTILINE_COMMENT_TOKEN:
        case END_OF_LINE_TOKEN:
            store_token(&token);
            return token_count;
        case LINE_COMMENT_TOKEN:
        case BLOCK_COMMENT_TOKEN:
            fputs(token.str, stdout);
        default:
            fputs(token.str, stdout);
            token_count++;
        }
    }
}
