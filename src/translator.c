#include <stdio.h>
#include <stdlib.h>

#include "input.h"
#include "token.h"
#include "error.h"
#include "indent.h"
#include "translator.h"

static Token look_ahead_token[2];
static int look_ahead_count;
static char context;

static void parse_statement(Token *, TranslatorStatus *, BlockStatus *, int *);
static void parse_block(Token *, TranslatorStatus, int *);
static int parse_expression(char);

static inline void
next_token(Token *token)
{
    if (look_ahead_count) {
        *token = look_ahead_token[--look_ahead_count];
    } else {
        get_indent(token);
    }
}

static inline void
store_token(Token *token)
{
    look_ahead_token[look_ahead_count++] = *token;
}

void
parse_file(void)
{
    Token token;
    context = -1;
    TranslatorStatus status = PREPROCESSOR;
    BlockStatus block = UNKNOWN_BLOCK;
    srand(RAND_MAX);
    look_ahead_queue(INIT);
    dputs("start!");
    for (;;) {
        dprintf(("\033[32m[TL46]\033[0m"));
        parse_statement(&token, &status, &block, NULL);
    }
    look_ahead_queue(DESTROY);
}

static void
parse_statement(Token *token, TranslatorStatus *status, BlockStatus *block, int *label)
{
    Token temp;
    for (;;) {
        parse_expression(0);
        next_token(token);
        switch (token->kind) {
        case KEYWORD_TOKEN:
            switch (token->type) {
            case 4: // do
                fputs("_do", output);
                continue;
            case 10: // fallthrough
                if (/* not_in_case */0) {
                    throw(34, "Unexpected keyword in this context", token);
                }
                if (*label < 0) {
                    *label = rand();
                }
                fprintf(output, "goto _fallthrough_%x;", *label);
                break;
            case 11: // pass
                fputc(';', output);
                continue;
            default:
                parse_block(token, AFTER_KEYWORD, label);
            }
            break;
        case END_OF_LINE_TOKEN:
        case MULTILINE_COMMENT_TOKEN:
            if (*status == BEFORE_INDENT) {
                throw(33, "Expected indent", token);
            } else if (*status != PREPROCESSOR) {
                if (*block != ENUM_BLOCK) {
                    fputc(';', output);
                }
            } else if (token->kind == END_OF_LINE_TOKEN) {
                *status = INITIAL_STATUS;
                if (context == -1) { // skip additional newline at BOF
                    context = 0;
                    token->str[0] = '\0';
                }
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
            next_token(&temp);
            if (temp.kind == UNINDENT_TOKEN) {
                store_token(token);
                store_token(&temp);
                return;
            } else if (temp.kind == END_OF_LINE_TOKEN) {
                temp.kind = ESCAPED_LINE_TOKEN;
            }
            fputc(';', output);
            fputs(token->str, output);
            store_token(&temp);
            continue;
        case INDENT_TOKEN:
            throw(32, "Unexpected indent", token);
        case UNINDENT_TOKEN:
            dprintf(("\033[31m[UN68]\033[0m"));
            store_token(token);
            return;
        case END_OF_FILE_TOKEN:
            throw(9, "Well done.", NULL);
        case COLON_TOKEN:
            store_token(token);
            parse_block(token, BEFORE_COLON, label);
            continue;
        default:
            throw(31, "Unhandled statement", token);
        }
    }
}

static void
parse_block(Token *token, TranslatorStatus status, int *label)
{
    int new_label = -1;
    BlockStatus block = UNKNOWN_BLOCK;
    if (status == BEFORE_COLON) {
        block = FUNCTION_BLOCK;
    } else do {
        switch (token->type) {
        case 0: case 3: case 5: // if (cond) { statement }
            block = token->type? WHILE_BLOCK: IF_BLOCK;
            fputs(token->str, output);
            fputc('(', output);
            break;
        case 1: // elif -> else if
            block = ELIF_BLOCK;
            if (!context) {
                throw(34, "Unexpected keyword in this context", token);
            }
            fputs("else if (", output);
            break;
        case 2: // else { statement }
            block = ELSE_BLOCK;
            if (!context) {
                throw(34, "Unexpected keyword in this context", token);
            }
            fputs(token->str, output);
            status = BEFORE_COLON;
            continue;
        case 6: // repeat (cond) { statement }
            block = REPEAT_BLOCK;
            new_label = rand();
            fprintf(output, "goto _repeat_%x; while (", new_label);
            break;
        case 7: // switch (foo) { statement }
            block = SWITCH_BLOCK;
            fputs(token->str, output);
            status = BEFORE_COLON;
            continue;
        case 8: // case 9, 7: statement
            block = CASE_BLOCK;
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
        case 9: // default: statement
            block = DEFAULT_BLOCK;
            if (!context) {
                throw(34, "Unexpected keyword in this context", token);
            }
            context = 0;
            fputs(token->str, output);
            status = BEFORE_COLON;
            continue;
        case 12: // typedef enum { list } name;
            block = ENUM_BLOCK;
            fputs(token->str, output);
            break;
        case 13: case 14: // struct name { list };
            block = STRUCT_BLOCK;
            fputs(token->str, output);
            break;
        default:
            throw(31, "Unhandled keyword", token);
            continue;
        }

        if (parse_expression(1)) {
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
                switch (block) {
                case REPEAT_BLOCK:
                    fprintf(output, ") { _repeat_%x: ", new_label);
                    break;
                case SWITCH_BLOCK:
                    fputc('(', output);
                    continue;
                case CASE_BLOCK:
                case DEFAULT_BLOCK:
                    label = &new_label;
                    fputs(token->str, output);
                    break;
                case IF_BLOCK:
                case ELIF_BLOCK:
                case WHILE_BLOCK:
                    fputc(')', output);
                    /* fallthrough; */
                default:
                    fputc('{', output);
                }
                if (parse_expression(1)) {
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
            parse_statement(token, &status, &block, label);
            continue;
        case UNINDENT_TOKEN:
            dprintf(("\033[33m[UN215]\033[0m"));
            switch (block) {
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
            switch (block) {
            case IF_BLOCK:
            case ELIF_BLOCK:
                if (token->type == 1 || token->type == 2) { // elif, else
                    context = 1;
                }
                fputc('}', output);
                break;
            case ENUM_BLOCK:
                break;
            case STRUCT_BLOCK:
                fputs("};", output);
                break;
            case SWITCH_BLOCK:
                if (token->type == 8 || token->type == 9) { // case, default
                    context = 1;
                } else {
                    throw(37, "Expected 'case' or 'default'", token);
                }
                break;
            case CASE_BLOCK:
                if (token->type == 8 || token->type == 9) { // case, default
                    context = 1;
                    fputs("break;", output);
                    if (new_label > 0) {
                        fprintf(output, " _fallthrough_%x: ;", new_label);
                    }
                    break;
                } else if (new_label > 0) {
                    throw(39, "Expected 'case' or 'default' after 'fallthrough'", token);
                }
                /* fallthrough; */
            default:
                fputc('}', output);
                break;
            }
            return;
        default:
            throw(31, "Unhandled token", token);
        }
    }
}

static inline int
parse_expression(char skip_comments)
{
    int token_count = 0;
    Token token;
    for (;;) {
        next_token(&token);
        switch (token.kind) {
        case LINE_COMMENT_TOKEN:
        case BLOCK_COMMENT_TOKEN:
        case MULTILINE_COMMENT_TOKEN:
            if (skip_comments) {
                fputs(token.str, output);
                continue;
            }
            /* fallthrough; */
        case INDENT_TOKEN:
        case UNINDENT_TOKEN:
        case KEYWORD_TOKEN:
        case COLON_TOKEN:
        case END_OF_LINE_TOKEN:
        case ESCAPED_LINE_TOKEN:
        case END_OF_FILE_TOKEN:
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
