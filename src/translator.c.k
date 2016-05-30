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

static void parse_statement(
    Token *,
    TranslatorStatus *,
    BlockStatus *,
    void *label
)
static void parse_block(
    Token *,
    TranslatorStatus,
    void *label
)
static int parse_expression(char)


static inline Token *next_token(Token *token):
    static TokenFamily previous
    if look_ahead_count:
        *token = look_ahead_token[--look_ahead_count]
    else:
        get_indent(token)
        if previous == UNINDENT_TOKEN && token->family == UNINDENT_TOKEN:
            token->type ^= 0x80 // add a semicolon
        previous = token->family
    return token


static inline void store_token(Token *token):
    look_ahead_token[look_ahead_count++] = *token


int parse_file(void):
    "Initialize the translator."
    Token token
    context = -1
    TranslatorStatus status = PREPROCESSOR
    BlockStatus block = UNKNOWN_BLOCK
    srand(RAND_MAX)

    int env = setjmp(exception)
    if !env:
        look_ahead_queue(INIT)
    else:
        look_ahead_queue(DESTROY)
        return env > 0? env: EXIT_SUCCESS

    for ;;:
        dprintf((BRIGHT + CYAN, "[top@%d]", __LINE__))
        int new_label = 0
        parse_statement(&token, &status, &block, &new_label)


static void struct_magic(const char *p, const char *q):
    "Append 'struct' before a self-referential field."
    #define isempty(x) (isspace(*(x)) || *(x) == '\0')
    while !isempty(p) && !isempty(q):
        if *p++ != *q++:
            return
    if isempty(p) && isempty(q):
        fputs("struct ", output)


static void parse_statement(
    Token *token,
    TranslatorStatus *status,
    BlockStatus *block,
    void *label
):
    "Parse statements in the same block, and add proper semicolons."
    Token temp
    for ;;:
        parse_expression(0)
        switch:
            next_token(token)->family

        case IDENTIFIER_TOKEN:
            if *block == STRUCT_BLOCK:
                struct_magic(label, token->str)
            fputs(token->str, output)

        case KEYWORD_TOKEN:
            switch:
                token->type
            case DO:
                fputs("_do", output)
            case FALLTHROUGH:
                if /* not_in_case */0:
                    throw(34, "Unexpected keyword in this context", token)
                while *(int *)label == 0:
                    *(int *)label = rand()
                fprintf(output, "goto _fallthrough_%x;", *(int *)label)
            case PASS:
                pass
            default:
                if (
                    *block == ENUM_BLOCK ||
                    (*block == STRUCT_BLOCK && token->type < ENUM)
                ):
                    throw(34, "Unexpected keyword in this context", token)
                parse_block(token, AFTER_KEYWORD, label)

        case END_OF_LINE_TOKEN, MULTILINE_COMMENT_TOKEN:
            if *status == BEFORE_INDENT:
                throw(33, "Expected indent", token)
            elif *status != PREPROCESSOR:
                if *block != ENUM_BLOCK:
                    if token->family != END_OF_LINE_TOKEN || !token->type:
                        fputc(';', output)
            elif token->family == END_OF_LINE_TOKEN && !token->type:
                *status = INITIAL_STATUS
                if context == -1: // skip additional newline at BOF
                    context = 0
                    token->str[0] = '\0'

            if next_token(&temp)->family == SHARP_TOKEN:
                *status = PREPROCESSOR
            store_token(&temp)
            fallthrough

        case BLOCK_COMMENT_TOKEN:
            fputs(token->str, output)

        case LINE_COMMENT_TOKEN:
            if next_token(&temp)->family == UNINDENT_TOKEN:
                token->type = INDENT_CHANGED
                store_token(token)
                store_token(&temp)
                return
            elif temp.family == END_OF_LINE_TOKEN:
                if token->type < 0 && !temp.type:
                    fputc(';', output)
                temp.type = BEFORE_COMMENT
            fputs(token->str, output)
            store_token(&temp)

        case INDENT_TOKEN:
            throw(32, "Unexpected indent", token)

        case UNINDENT_TOKEN:
            store_token(token)
            return

        case END_OF_FILE_TOKEN:
            free(line)
            line = NULL
            longjmp(exception, -1)

        case COLON_TOKEN:
            store_token(token)
            parse_block(token, BEFORE_COLON, label)

        default:
            throw(31, "Unhandled statement", token)


static void parse_block(
    Token *token,
    TranslatorStatus status,
    void *label
):
    "Process an indented block or an inline block."
    int new_label = 0
    char type_name[MAX_TOKEN_SIZE]
    BlockStatus block = UNKNOWN_BLOCK
    dprintf((GREEN, "[@%d]", __LINE__))
    if status == BEFORE_COLON:
        block = FUNCTION_BLOCK
        goto conditions_processed

    int expected_conditions = 0
    switch:
        token->type

    case IF, FOR, WHILE:
        block = token->type == IF? IF_BLOCK: WHILE_BLOCK
        fputs(token->str, output)
        fputc('(', output)
        expected_conditions = 1

    case ELIF:
        block = ELIF_BLOCK
        if !context:
            throw(34, "Unexpected keyword in this context", token)
        fputs("else if (", output)
        expected_conditions = 1

    case ELSE:
        block = ELSE_BLOCK
        if !context:
            throw(34, "Unexpected keyword in this context", token)
        fputs(token->str, output)

    case REPEAT:
        block = REPEAT_BLOCK
        new_label = rand()
        fprintf(output, "goto _repeat_%x; while (", new_label)
        expected_conditions = 1

    case SWITCH:
        block = SWITCH_BLOCK
        fputs(token->str, output)

    case CASE:
        block = CASE_BLOCK
        if !context:
            throw(34, "Unexpected keyword in this context", token)
        while token->family != COLON_TOKEN:
            switch:
                token->family
            case COMMA_TOKEN:
                fputs(": case ", output)
            case END_OF_LINE_TOKEN:
                switch:
                    token->type
                case 1, 2, 5:
                    pass
                default:
                    throw(36, "Expected colons", token)
            case END_OF_FILE_TOKEN:
                throw(36, "Expected colons", NULL)
            default:
                dprintf((MAGENTA, "[%d,%s]", token->family, token->str))
                fputs(token->str, output)
            next_token(token)
        store_token(token)

    case DEFAULT:
        block = DEFAULT_BLOCK
        if !context:
            throw(34, "Unexpected keyword in this context", token)
        context = 0
        fputs(token->str, output)

    case ENUM, STRUCT, UNION:
        block = token->type == ENUM? ENUM_BLOCK: STRUCT_BLOCK
        fputs("typedef ", output)
        fputs(token->str, output)

        while next_token(token)->family == BLOCK_COMMENT_TOKEN:
            fputs(token->str, output)

        if token->family == IDENTIFIER_TOKEN:
            strcpy(type_name, token->str)
            fputs(token->str, output)
        else:
            throw(35, "Expected type name before colon", token)

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
            next_token(token)->family

        case COLON_TOKEN:
            if status != BEFORE_COLON:
                throw(36, "Unexpected colons", token)
            else:
                status = BEFORE_INDENT
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

                if parse_expression(0x1 | 0x2 | 0x4):
                    status = INLINE_BLOCK

                    switch:
                        next_token(token)->family

                    case IDENTIFIER_TOKEN:
                        if block == STRUCT_BLOCK:
                            struct_magic(label, token->str)
                        fputs(token->str, output)

                    Token temp = {
                        .family = UNINDENT_TOKEN,
                        .row = token->row,
                        .column = token->column,
                        .type = PASS
                    }
                    store_token(&temp)

        case INDENT_TOKEN:
            if status != BEFORE_INDENT:
                throw(32, "Unexpected indent", token)
            status = BEFORE_UNINDENT
            parse_statement(token, &status, &block, label)

        case UNINDENT_TOKEN:
            dprintf((RED, "[@%d]", __LINE__))
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
                if token->type == ELIF || token->type == ELSE:
                    context = 1
                fputc('}', output)
            case ENUM_BLOCK, STRUCT_BLOCK:
                fprintf(output, "} %s;", type_name)
            case SWITCH_BLOCK:
                if token->type == CASE || token->type == DEFAULT:
                    context = 1
                else:
                    throw(37, "Expected 'case' or 'default'", token)
            case CASE_BLOCK:
                if token->type == CASE || token->type == DEFAULT:
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
            return

        default:
            if status == BEFORE_INDENT:
                throw(33, "Expected indent", token)
            elif token->family == END_OF_FILE_TOKEN || token->family == END_OF_LINE_TOKEN:
                throw(30, "Unexpected EOF", token)
            else:
                throw(31, "Unhandled token", token)


static inline int parse_expression(char options):
    "Print and count untouched tokens."
    int token_count = 0
    Token token
    for ;;:
        switch:
            next_token(&token)->family

        case LINE_COMMENT_TOKEN, BLOCK_COMMENT_TOKEN, MULTILINE_COMMENT_TOKEN:
            if !(options & 0x1):
                goto exit
            else:
                fputs(token.str, output)
                continue

        case IDENTIFIER_TOKEN:
            if !(options & 0x2):
                goto exit

        case END_OF_LINE_TOKEN:
            if !(options & 0x4) || !token.type:
                goto exit
            else:
                fputs(token.str, output)
                continue

        case KEYWORD_TOKEN:
            if token.type == PASS || token.type == DO:
                continue
            else:
                goto exit

        case INDENT_TOKEN, UNINDENT_TOKEN, COLON_TOKEN, END_OF_FILE_TOKEN:
            goto exit

        case GOTO_TAG_TOKEN:
            fputc(':', output) // => -> :
            fputs(token.str + 2, output)
            continue

        fputs(token.str, output)
        token_count++

    exit => store_token(&token)
    return token_count
