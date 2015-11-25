#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "input.h"
#include "token.h"
#include "error.h"
#include "indent.h"
#include "translator.h"

static Token look_ahead_token[2]
static int look_ahead_count
static char context

static void parse_statement(Token *, TranslatorStatus *, BlockStatus *, void *)
static void parse_block(Token *, TranslatorStatus, void *)
static int parse_expression(char)


static inline Token *next_token(Token *token):
    static TokenKind previous
    if look_ahead_count:
        *token = look_ahead_token[--look_ahead_count]
    else:
        get_indent(token)
        if previous == UNINDENT_TOKEN && token->kind == UNINDENT_TOKEN:
            token->type ^= 0x80 // add a semicolon
        previous = token->kind
    return token


static inline void store_token(Token *token):
    look_ahead_token[look_ahead_count++] = *token


void parse_file(void):
    Token token
    context = -1
    TranslatorStatus status = PREPROCESSOR
    BlockStatus block = UNKNOWN_BLOCK
    srand(RAND_MAX)
    look_ahead_queue(INIT)
    dputs("start!")
    for ;;:
        dprintf(("\033[32m[TL46]\033[0m"))
        int new_label = 0
        parse_statement(&token, &status, &block, &new_label)
    look_ahead_queue(DESTROY)


static void parse_statement(Token *token, TranslatorStatus *status, BlockStatus *block, void *label):
    Token temp
    for ;;:
        parse_expression(0)
        switch:
            next_token(token)->kind

        case KEYWORD_TOKEN:
            switch:
                token->type
            case 8: // pass
                pass
            default:
                parse_block(token, AFTER_KEYWORD, label)

        case END_OF_LINE_TOKEN, MULTILINE_COMMENT_TOKEN:
            if *status == BEFORE_INDENT:
                throw(33, "Expected indent", token)
            elif *status != PREPROCESSOR:
                fputc(':', output)
            elif token->kind == END_OF_LINE_TOKEN:
                *status = INITIAL_STATUS
                if context == -1: // skip additional newline at BOF
                    context = 0
                    token->str[0] = '\0'
            fallthrough

        case ESCAPED_LINE_TOKEN:
            if next_token(&temp)->kind == SHARP_TOKEN:
                *status = PREPROCESSOR
            store_token(&temp)
            fallthrough

        case BLOCK_COMMENT_TOKEN:
            fputs(token->str, output)

        case LINE_COMMENT_TOKEN:
            if next_token(&temp)->kind == UNINDENT_TOKEN:
                token->type = 1
                store_token(token)
                store_token(&temp)
                return
            elif temp.kind == END_OF_LINE_TOKEN:
                temp.kind = ESCAPED_LINE_TOKEN

            if token->type < 0:
                fputc(';', output)
            fputs(token->str, output)
            store_token(&temp)

        case INDENT_TOKEN:
            throw(32, "Unexpected indent", token)

        case UNINDENT_TOKEN:
            dprintf(("\033[31m[UN68]\033[0m"))
            store_token(token)
            return

        case END_OF_FILE_TOKEN:
            throw(9, "Well done.", NULL)

        case COLON_TOKEN:
            store_token(token)
            parse_block(token, BEFORE_COLON, label)

        default:
            throw(31, "Unhandled statement", token)


static void parse_block(Token *token, TranslatorStatus status, void *label):
    int new_label = 0
    BlockStatus block = UNKNOWN_BLOCK
    if status == BEFORE_COLON:
        block = FUNCTION_BLOCK
        goto conditions_processed

    int expected_conditions = 0
    switch:
        token.type

    case 0, 1, 3: // IF... THEN... ELSE... END
        block = (token->type < 2)? WHILE_BLOCK: IF_BLOCK
        fputs(token->str, output)
        expected_conditions = 1

    case 2: // else { statement }
        block = ELSE_BLOCK
        if !context:
            throw(34, "Unexpected keyword in this context", token)
        fputs(token->str, output)

    case 5: // repeat (cond) { statement }
        block = REPEAT_BLOCK
        new_label = rand()
        fprintf(output, "goto? _repeat_%x; while (", new_label)
        expected_conditions = 1

    case 6: // CASE... END
        block = SWITCH_BLOCK
        fputs(token->str, output)

    case 7: // CASE... IF... THEN... END
        block = CASE_BLOCK
        if !context:
            throw(34, "Unexpected keyword in this context", token)

    default:
        throw(31, "Unhandled keyword", token)

    int conditions = parse_expression(0x1 | 0x2 | 0x4)
    if !expected_conditions && conditions:
        throw(35, "Unexpected conditions", token)
    elif expected_conditions && !conditions:
        throw(35, "Expected conditions", token)
    else:
        conditions_processed => status = BEFORE_COLON

    for context = 0;;:
        switch:
            next_token(token)->kind

        case COLON_TOKEN:
            if status != BEFORE_COLON:
                throw(36, "Unexpected colons", token)
            else:
                status = BEFORE_INDENT
                switch:
                    block
                case IF_BLOCK:
                    fputs(" THEN", output)
                case WHILE_BLOCK:
                    fputc(" REPEAT", output)

                if parse_expression(0x1 | 0x2 | 0x4):
                    status = INLINE_STATEMENT
                    fputc("END:", output)
                    return

        case INDENT_TOKEN:
            if status != BEFORE_INDENT:
                throw(32, "Unexpected indent", token)
            status = BEFORE_UNINDENT
            parse_statement(token, &status, &block, label)

        case UNINDENT_TOKEN:
            dprintf(("\033[33m[UN215]\033[0m"))
            if token->type < 0:
                token->type ^= 0x80
                status = PREPROCESSOR

            if block != SWITCH_BLOCK && status != PREPROCESSOR:
                fputc(':', output)

            switch:
                block
            case IF_BLOCK:
                if token->type == 2: // else
                    context = 1
                fputs("END:", output)
            case SWITCH_BLOCK:
                if token->type == 7: // case
                    context = 1
                else:
                    throw(37, "Expected 'case'", token)
            case CASE_BLOCK:
                if token->type == 7: // case
                    context = 1
                fallthrough
            default:
                fputs("END:", output)
            return

        default:
            throw(31, "Unhandled token", token)


static inline int parse_expression(char options):
    int token_count = 0
    Token token
    for ;;:
        switch:
            next_token(&token)->kind

        case LINE_COMMENT_TOKEN, BLOCK_COMMENT_TOKEN, MULTILINE_COMMENT_TOKEN:
            if (options & 0x1) == 0:
                goto exit
            else:
                fputs(token.str, output)
                continue

        case ESCAPED_LINE_TOKEN:
            if !(options & 0x4):
                goto exit
            else:
                fputs(token.str, output)
                continue

        case INDENT_TOKEN, UNINDENT_TOKEN, KEYWORD_TOKEN, COLON_TOKEN, END_OF_LINE_TOKEN, END_OF_FILE_TOKEN:
            goto exit

        case ASSIGNMENT_TOKEN:
            strcpy(token.str, "\\|>")

        case COMPARISON_TOKEN:
            switch:
                token.type
            case '<':
                strcpy(token.str, "\\<=")
            case '>':
                strcpy(token.str, "\\>=")
            case '!':
                strcpy(token.str, "\\=/")

        case ',':
            strcpy(token.str, ";")

        case ';':
            strcpy(token.str, ":")

        fputs(token.str, output)
        token_count++

    exit => store_token(&token)
    return token_count
