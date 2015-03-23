#include <stdio.h>

#include "input.h"
#include "token.h"
#include "error.h"
#include "indent.h"
#include "translator.h"

#define NONEXISTENT (0x7F)

static Token look_ahead_token;

static void parse_statement(Token *, TranslatorStatus *, IndentStatus *);
static void parse_block(Token *, TranslatorStatus);
static int parse_expression(void);

static inline void
next_token(Token *token)
{
    if (look_ahead_token.type == NONEXISTENT) {
        get_indent(token);
    } else {
        *token = look_ahead_token;
        look_ahead_token.type = NONEXISTENT;
    }
}

static inline void
store_token(Token *token)
{
    look_ahead_token = *token;
}

void
parse_file(void)
{
    Token token;
    TranslatorStatus status = INITIAL_STATUS;
    IndentStatus pending = UNKNOWN;
    look_ahead_token.type = NONEXISTENT;
    look_ahead_queue(INIT);
    dputs("start!");
    for (;;) {
        dprintf(("\033[32m[TL46]\033[0m"));
        parse_statement(&token, &status, &pending);
    }
    look_ahead_queue(DESTROY);
}

static void
parse_statement(Token *token, TranslatorStatus *status, IndentStatus *pending)
{
    for (;;) {
        parse_expression();
        next_token(token);
        switch (token->kind) {
        case BAD_TOKEN:
            throw(31, "Unhandled token", token);
        case INDENT_TOKEN:
            throw(32, "Unexpected indent", token);
        case UNINDENT_TOKEN:
            dprintf(("\033[31m[UN68]\033[0m"));
            store_token(token);
            return;
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
        case MULTILINE_COMMENT_TOKEN:
            if (*status == BEFORE_INDENT) {
                throw(33, "Expected indent", token);
            } else if (*status != PREPROCESSOR) {
                if (*pending != ENUM_BLOCK) {
                    putchar(';');
                }
            } else if (token->kind == END_OF_LINE_TOKEN) {
                *status = INITIAL_STATUS;
            }
            /* fallthrough; */
        case ESCAPED_LINE_TOKEN:
            fputs(token->str, stdout);

            next_token(token);
            if (token->kind == SHARP_TOKEN) {
                *status = PREPROCESSOR;
            }
            store_token(token);
            continue;
        case SCOPE_TOKEN:
            throw(0, "end!", NULL);
        default:
            dputs("Unhandled default!");
        }
    }
}

static void
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
            if (parse_expression()) {
                status = BEFORE_COLON;
            } else {
                throw(37, "Expected conditions before colon", token);
            }
            break;
        case 12: // typedef enum { list } name;
            pending = ENUM_BLOCK;
            fputs(token->str, stdout);
            parse_expression();
            status = BEFORE_COLON;
            break;
        case 7: // switch (foo) { statement }
            pending = SWITCH_BLOCK;
            fputs(token->str, stdout);
            status = BEFORE_COLON;
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
                throw(34, "Unexpected keyword in this context", token);
            }
        case 1: // else { statement }
            pending = ELSE_BLOCK;
            fputs(token->str, stdout);
            status = BEFORE_COLON;
            break;
        case 6: // repeat (cond) { statement }
            pending = REPEAT_BLOCK;
            fputs(token->str, stdout);
            parse_expression();
            status = BEFORE_COLON;
            break;
        case 13: case 14: // typedef struct { list } name;
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
                throw(35, "Expected conditions before colon", token);
            case BEFORE_COLON:
                status = BEFORE_INDENT;
                switch (pending) {
                case SWITCH_BLOCK:
                    putchar('(');
                    continue;
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
                throw(36, "Unexpected colons", token);
            }
            continue;
        case INDENT_TOKEN:
            if (status != BEFORE_INDENT) {
                throw(32, "Unexpected indent", token);
            }
            status = BEFORE_UNINDENT;
            parse_statement(token, &status, &pending);
            continue;
        case UNINDENT_TOKEN:
            dprintf(("\033[33m[UN215]\033[0m"));
            switch (pending) {
            case SWITCH_BLOCK:
                putchar(')');
                putchar('{');
                break;
            case REPEAT_BLOCK:
            case ENUM_BLOCK:
                printf("} while (%s);", "cond");
                break;
            case FUNCTION_BLOCK:
            case IF_BLOCK:
            case ELSE_BLOCK:
                if (status != PREPROCESSOR) {
                    putchar(';');
                }
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

static inline int
parse_expression(void)
{
    int token_count = 0;
    Token token;
    for (;;) {
        next_token(&token);
        switch (token.kind) {
        case BAD_TOKEN:
        case INDENT_TOKEN:
        case UNINDENT_TOKEN:
        case KEYWORD_TOKEN:
        case COLON_TOKEN:
        case MULTILINE_COMMENT_TOKEN:
        case END_OF_LINE_TOKEN:
        case ESCAPED_LINE_TOKEN:
        case SCOPE_TOKEN:
            store_token(&token);
            return token_count;
        case LINE_COMMENT_TOKEN:
        case BLOCK_COMMENT_TOKEN:
            fputs(token.str, stdout);
            continue;
        default:
            fputs(token.str, stdout);
            token_count++;
        }
    }
}
