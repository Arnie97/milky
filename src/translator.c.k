#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "input.h"
#include "token.h"
#include "error.h"
#include "indent.h"
#include "translator.h"

#define retblk { return block; }

static Token look_ahead_token[2]
static int look_ahead_count
static char context

static void parse_statement(Token *, TranslatorStatus *, BlockStatus *, void *)
static void parse_block(Token *, TranslatorStatus, void *)
static int parse_expression(char)


static inline void next_token(Token *token):
    static TokenKind previous
    if look_ahead_count:
        *token = look_ahead_token[--look_ahead_count]
    else:
        get_indent(token)
        if previous == UNINDENT_TOKEN && token->kind == UNINDENT_TOKEN:
            token->type ^= 0x80 // add a semicolon
        previous = token->kind


static inline void store_token (Token *token):
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
        parse_expression(2)
        next_token(token)
        switch:
            token->kind
        case IDENTIFIER_TOKEN:
            if *block == STRUCT_BLOCK:
                #define isempty(x) (isspace(*(x)) || *(x) == '\0')
                char *p = label, *q = token->str
                while !isempty(p) && !isempty(q):
                    if *p++ != *q++:
                        goto hell
                if isempty(p) && isempty(q):
                    fputs("struct ", output)
            hell => fputs(token->str, output)
        case KEYWORD_TOKEN:
            switch:
                token->type
            case 4: // do
                fputs("_do", output)
            case 10: // fallthrough
                if /* not_in_case */0:
                    throw(34, "Unexpected keyword in this context", token)
                while *(int *)label == 0:
                    *(int *)label = rand()
                fprintf(output, "goto _fallthrough_%x;", *(int *)label)
            case 11: // pass
                pass
            default:
                parse_block(token, AFTER_KEYWORD, label)
        case END_OF_LINE_TOKEN, MULTILINE_COMMENT_TOKEN:
            if *status == BEFORE_INDENT:
                throw(33, "Expected indent", token)
            elif *status != PREPROCESSOR:
                if *block != ENUM_BLOCK:
                    fputc(';', output)
            elif token->kind == END_OF_LINE_TOKEN:
                *status = INITIAL_STATUS
                if context == -1: // skip additional newline at BOF
                    context = 0
                    token->str[0] = '\0'
            fallthrough
        case ESCAPED_LINE_TOKEN:
            next_token(&temp)
            if temp.kind == SHARP_TOKEN:
                *status = PREPROCESSOR
            store_token(&temp)
            fallthrough
        case BLOCK_COMMENT_TOKEN:
            fputs(token->str, output)
        case LINE_COMMENT_TOKEN:
            next_token(&temp)
            if temp.kind == UNINDENT_TOKEN:
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


static BlockStatus parse_block_header(Token *token, int *new_label, char *type_name):
    BlockStatus block
    switch:
        token->type
    case 0, 3, 5: // if (cond) { statement }
        block = token->type? WHILE_BLOCK: IF_BLOCK
        fputs(token->str, output)
        fputc('(', output)
    case 1: // elif -> else if
        block = ELIF_BLOCK
        if !context:
            throw(34, "Unexpected keyword in this context", token)
        fputs("else if (", output)
    case 2: // else { statement }
        block = ELSE_BLOCK
        if !context:
            throw(34, "Unexpected keyword in this context", token)
        fputs(token->str, output)
        retblk
    case 6: // repeat (cond) { statement }
        block = REPEAT_BLOCK
        *new_label = rand()
        fprintf(output, "goto _repeat_%x; while (", *new_label)
    case 7: // switch (expr) { statement }
        block = SWITCH_BLOCK
        fputs(token->str, output)
        retblk
    case 8: // case 9, 7: statement
        block = CASE_BLOCK
        if !context:
            throw(34, "Unexpected keyword in this context", token)
        while token->kind != COLON_TOKEN:
            if token->kind == COMMA_TOKEN:
                fputs(": case ", output)
            else:
                fputs(token->str, output)
            next_token(token)
        store_token(token)
        retblk
    case 9: // default: statement
        block = DEFAULT_BLOCK
        if !context:
            throw(34, "Unexpected keyword in this context", token)
        context = 0
        fputs(token->str, output)
        retblk
    case 12, 13, 14: // typedef struct { list } name
        block = (token->type == 12)? ENUM_BLOCK: STRUCT_BLOCK
        fputs("typedef ", output)
        fputs(token->str, output)
        next_token(token)
        if token->kind == IDENTIFIER_TOKEN:
            strcpy(*type_name, token->str)
            fputs(token->str, output)
        else:
            throw(35, "Expected type name before colon", token)
        retblk
    default:
        throw(31, "Unhandled keyword", token)

    // if, elif, while, for, repeat
    if !parse_expression(1):
        throw(35, "Expected conditions before colon", token)
    retblk


static void parse_block(Token *token, TranslatorStatus status, void *label):
    int new_label = 0
    char type_name[MAX_TOKEN_SIZE]

    BlockStatus block = UNKNOWN_BLOCK
    if status == BEFORE_COLON:
        block = FUNCTION_BLOCK
    else:
        block = parse_block_header(token, &new_label, &type_name)
        status = BEFORE_COLON

    context = 0
    while 1:
        next_token(token)
        switch:
            token->kind
        case COLON_TOKEN:
            if status != BEFORE_COLON:
                throw(36, "Unexpected colons", token)
            // else:
            status = BEFORE_INDENT
            label = parse_colon(token, new_label, type_name) || label
            if parse_expression(1):
                status = INLINE_STATEMENT
                fputc('}', output)
                return
        case INDENT_TOKEN:
            if status != BEFORE_INDENT:
                throw(32, "Unexpected indent", token)
            status = BEFORE_UNINDENT
            parse_statement(token, &status, &block, &new_label, type_name)
        case UNINDENT_TOKEN:
            parse_unindent(token, status, block, new_label)
            return
        default:
            throw(31, "Unhandled token", token)


static void *parse_colon(Token *token, BlockStatus block, int new_label, char *type_name):
    void *label = NULL
    switch:
        block
    case REPEAT_BLOCK:
        fprintf(output, "){ _repeat_%x: ", new_label)
    case SWITCH_BLOCK:
        fputc('(', output)
        continue
    case CASE_BLOCK, DEFAULT_BLOCK:
        label = &new_label
        fputs(token->str, output)
        fputc(';', output) // declaration magic
    case STRUCT_BLOCK:
        label = &type_name
        fputc('{', output)
    case IF_BLOCK, ELIF_BLOCK, WHILE_BLOCK:
        fputc(')', output)
        fallthrough
    default:
        fputc('{', output)
    return label


static void parse_unindent(Token *token, TranslatorStatus status, BlockStatus block, int new_label):
    dprintf(("\033[33m[UN215]\033[0m"))
    if token->type < 0:
        token->type ^= 0x80
        status = PREPROCESSOR
    switch:
        block
    case SWITCH_BLOCK:
        fputs("){", output)
    case ENUM_BLOCK:
        pass
    default:
        if status != PREPROCESSOR:
            fputc(';', output)

    switch:
        block
    case IF_BLOCK, ELIF_BLOCK:
        if token->type == 1 || token->type == 2: // elif, else
            context = 1
        fputc('}', output)
    case ENUM_BLOCK, STRUCT_BLOCK:
        fprintf(output, "} %s;", type_name)
    case SWITCH_BLOCK:
        if token->type == 8 || token->type == 9: // case, default
            context = 1
        else:
            throw(37, "Expected 'case' or 'default'", token)
    case CASE_BLOCK:
        if token->type == 8 || token->type == 9: // case, default
            context = 1
            fputs("break;", output)
            if new_label:
                fprintf(output, " _fallthrough_%x: ;", new_label)
        elif new_label:
            throw(39, "Expected 'case' or 'default' after 'fallthrough'", token)
        else:
            fallthrough
    default:
        fputc('}', output)


static inline int parse_expression(char options):
    int token_count = 0
    Token token
    for ;;:
        next_token(&token)
        switch:
            token.kind
        case LINE_COMMENT_TOKEN, BLOCK_COMMENT_TOKEN, MULTILINE_COMMENT_TOKEN:
            if (options & 0x1): // 0x1 keeps comments
                fputs(token.str, output)
                continue
            else:
                fallthrough
        case IDENTIFIER_TOKEN:
            if (options & 0x2) || token.kind != IDENTIFIER_TOKEN:
                fallthrough // 0x2 returns identifiers
        case INDENT_TOKEN, UNINDENT_TOKEN, KEYWORD_TOKEN, COLON_TOKEN:
            fallthrough
        case END_OF_LINE_TOKEN, ESCAPED_LINE_TOKEN, END_OF_FILE_TOKEN:
            store_token(&token)
            return token_count
        case GOTO_TAG_TOKEN:
            fputc(':', output); // => -> :
            fputs(token.str + 2, output)
            continue
        fputs(token.str, output)
        token_count++
