#include <stdio.h>
#include <stdlib.h>

#include "input.h"
#include "token.h"
#include "error.h"
#include "indent.h"
#include "translator.h"

#define NONEXISTENT (0x7F)

static Token look_ahead_token;
static char context;

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
    srand(RAND_MAX);
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
    Token temp;
    for (;;) {
        parse_expression();
        next_token(token);
        switch (token->kind) {
        case INDENT_TOKEN:
            throw(32, "Unexpected indent", token);
        case UNINDENT_TOKEN:
            dprintf(("\033[31m[UN68]\033[0m"));
            store_token(token);
            return;
        case KEYWORD_TOKEN:
            switch (token->type) {
            case 4: // do
                fputs("_do", output);
                continue;
            case 10: // fallthrough;
                break;
            case 11: // pass;
                fputc(';', output);
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
                    fputc(';', output);
                }
            } else if (token->kind == END_OF_LINE_TOKEN) {
                *status = INITIAL_STATUS;
            }
            /* fallthrough; */
        case ESCAPED_LINE_TOKEN:
            next_token(&temp);
            if (temp.kind == SHARP_TOKEN) {
                *status = PREPROCESSOR;
            }
            store_token(&temp);
            /* fallthrough; */
        case BLOCK_COMMENT_TOKEN:
            fputs(token->str, output);
            continue;
        case LINE_COMMENT_TOKEN:
            fputc(';', output);
            fputs(token->str, output);
            next_token(token);
            if (token->kind == END_OF_LINE_TOKEN) {
                token->kind = ESCAPED_LINE_TOKEN;
            }
            store_token(token);
            continue;
        case END_OF_FILE_TOKEN:
            throw(0, "end!", NULL);
        default:
            dputs("Unhandled default!");
        }
    }
}

static void
parse_block(Token *token, TranslatorStatus status)
{
    int repeat_label;
    IndentStatus pending = UNKNOWN;
    if (status == BEFORE_COLON) {
        pending = FUNCTION_BLOCK;
    } else do {
        switch (token->type) {
        case 0: case 3: case 5: // if (cond) { statement }
            pending = token->type? WHILE_BLOCK: IF_BLOCK;
            fputs(token->str, output);
            fputc('(', output);
            break;
        case 2: // elif
            pending = ELIF_BLOCK;
            if (!context) {
                throw(34, "Unexpected keyword in this context", token);
            }
            fputs("else if (", output);
            break;
        case 6: // repeat (cond) { statement }
            pending = REPEAT_BLOCK;
            repeat_label = rand();
            fprintf(output, "goto _repeat_%x; while (", repeat_label);
            break;
        case 12: // typedef enum { list } name;
            pending = ENUM_BLOCK;
            fputs(token->str, output);
            break;
        case 13: case 14: // struct name { list };
            pending = STRUCT_BLOCK;
            fputs(token->str, output);
            break;
        case 7: // switch (foo) { statement }
            pending = SWITCH_BLOCK;
            fputs(token->str, output);
            status = BEFORE_COLON;
            continue;
        case 9: // default: statement
            pending = DEFAULT_BLOCK;
            if (!context) {
                throw(34, "Unexpected keyword in this context", token);
            }
            context = 0;
            fputs(token->str, output);
            status = BEFORE_COLON;
            continue;
        case 8: // case 9, 7: statement
            pending = CASE_BLOCK;
            if (!context) {
                throw(34, "Unexpected keyword in this context", token);
            }
            while (token->kind != COLON_TOKEN) {
                if (token->kind == COMMA_TOKEN) {
                    fputs(": case ", output);
                } else {
                    fputs(token->str, output);
                }
                next_token(token);
            }
            store_token(token);
            status = BEFORE_COLON;
            continue;
        case 1: // else { statement }
            pending = ELSE_BLOCK;
            if (!context) {
                throw(34, "Unexpected keyword in this context", token);
            }
            fputs(token->str, output);
            status = BEFORE_COLON;
            continue;
        default:
            dputs("Unhandled keyword!");
            continue;
        }

        if (parse_expression()) {
            status = BEFORE_COLON;
        } else {
            throw(35, "Expected conditions before colon", token);
        }
    } while (0);

    for (context = 0;;) {
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
                    fputc('(', output);
                    continue;
                case CASE_BLOCK:
                case DEFAULT_BLOCK:
                    fputs(token->str, output);
                    break;
                case REPEAT_BLOCK:
                    fprintf(output, ") { _repeat_%x: ", repeat_label);
                    break;
                case IF_BLOCK:
                case ELIF_BLOCK:
                case WHILE_BLOCK:
                    fputc(')', output);
                    /* fallthrough; */
                default:
                    fputc('{', output);
                }
                if (parse_expression()) {
                    status = INLINE_STATEMENT;
                    fputc('}', output);
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
                fputs("){", output);
                break;
            case ENUM_BLOCK:
                fprintf(output, "} %s;", "token_t");
                break;
            default:
                if (status != PREPROCESSOR) {
                    fputc(';', output);
                }
                break;
            }
            switch (pending) {
            case IF_BLOCK:
            case ELIF_BLOCK:
                if (token->type == 1 || token->type == 2) { // elif, else
                    context = 1;
                }
                fputc('}', output);
                break;
            case SWITCH_BLOCK:
                if (token->type == 8 || token->type == 9) { // case, default
                    context = 1;
                } else {
                    throw(37, "Expected 'case' or 'default'", token);
                }
                break;
            case STRUCT_BLOCK:
                fputs("};", output);
                break;
            case ENUM_BLOCK:
                break;
            case CASE_BLOCK:
                if (token->type == 8 || token->type == 9) { // case, default
                    context = 1;
                    fputs("break;", output);
                    break;
                }
                /* fallthrough; */
            default:
                fputc('}', output);
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
        case INDENT_TOKEN:
        case UNINDENT_TOKEN:
        case KEYWORD_TOKEN:
        case COLON_TOKEN:
        case MULTILINE_COMMENT_TOKEN:
        case END_OF_LINE_TOKEN:
        case ESCAPED_LINE_TOKEN:
        case END_OF_FILE_TOKEN:
        case BLOCK_COMMENT_TOKEN:
        case LINE_COMMENT_TOKEN:
            store_token(&token);
            return token_count;
        case SCOPE_TOKEN:
            fputs(token.str + 1, output); // :: -> :
            break;
        default:
            fputs(token.str, output);
        }
        token_count++;
    }
}
