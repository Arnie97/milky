#include <stdio.h>
#include <string.h>

#include "token.h"
#include "queue.h"
#include "error.h"
#include "lexer.h"
#include "indent.h"

#define MAX_INDENTATION_LEVEL (20)

Queue *look_ahead_tokens

int *strchr_i(register const int *s, int c)
size_t strlen_i(const int *s)


static void get_escaped(Token *token):
    static int ternary_expressions, unclosed_brackets
    switch:
        token->kind
    case '(', '[', '{':
        unclosed_brackets++
    case ')', ']', '}':
        unclosed_brackets--
    case '?':
        ternary_expressions++
    case ':':
        if ternary_expressions:
            ternary_expressions--
            token->kind = ESCAPED_COLON_TOKEN
    case END_OF_LINE_TOKEN:
        if unclosed_brackets:
            token->type = 2
    case MULTILINE_COMMENT_TOKEN:
        if unclosed_brackets:
            token->kind = BLOCK_COMMENT_TOKEN


static inline void next_token(Token *token, char force_look_ahead):
    if !force_look_ahead && look_ahead_tokens->size:
        dequeue(look_ahead_tokens, token)
    else:
        get_whitespace(token, get_token(token))
        get_escaped(token)


static inline void store_token(Token *token):
    enqueue(look_ahead_tokens, *token)


void get_indent(Token *token):
    static char settled_by, indent_just_changed
    static int indent_settled, current_indent
    static int indents[MAX_INDENTATION_LEVEL] = { 0 }
    char first_new_line = 1

    while !indent_settled:
        next_token(token, 1)
        hell => switch:
            token->kind

        case MULTILINE_COMMENT_TOKEN: // empty line ending with MULTILINE
            current_indent = strrchr(token->str, '\n') - token->str + 1
            current_indent = strlen(token->str) - current_indent / sizeof(char)
            if first_new_line:
                first_new_line = 0
            else:
                token->kind = BLOCK_COMMENT_TOKEN
            store_token(token)
            continue

        case END_OF_LINE_TOKEN: // empty line too
            if token->type:
                throw(21, "Escaping an empty line", token)
            else:
                current_indent = -1

            if first_new_line:
                first_new_line = 0
            else:
                token->type = 3

        case LINE_COMMENT_TOKEN:
            token->type = 1

        case BLOCK_COMMENT_TOKEN:
            pass

        case SHARP_TOKEN:
            while (
                !(token->kind == END_OF_LINE_TOKEN && !token->type) &&
                token->kind != MULTILINE_COMMENT_TOKEN &&
                token->kind != END_OF_FILE_TOKEN
            ):
                if token->kind == KEYWORD_TOKEN:
                    token->kind = IDENTIFIER_TOKEN
                store_token(token)
                next_token(token, 1)

            if token->kind == END_OF_FILE_TOKEN:
                fallthrough
            else:
                first_new_line = 1
                goto hell

        case KEYWORD_TOKEN:
            settled_by = token->type
            fallthrough

        default:
            indent_settled = 1
            store_token(token)
            continue

        current_indent += strlen(token->str)
        store_token(token)

    // indent just settled, token not inserted
    int indent_levels = strlen_i(indents)
    int last_indent = indent_levels? indents[indent_levels - 1]: 0
    int indent_change = current_indent - last_indent
    if indent_change > 0:
        token->kind = INDENT_TOKEN
        token->str[0] = '\0'
        dprintf(("\033[32m[IN %d->%d]\033[0m", last_indent, current_indent))
        indents[indent_levels] = current_indent

        token->type = settled_by
        settled_by = 0

        indent_just_changed = 1
        return

    if indent_change < 0:
        token->kind = UNINDENT_TOKEN
        token->str[0] = '\0'
        if !strchr_i(indents, current_indent):
            throw(22, "Unindent does not match any outer indentation level", token)
        dprintf(("\033[33m[UN %d->%d]\033[0m", last_indent, current_indent))
        indents[indent_levels - 1] = 0

        if indents[indent_levels - 2] == current_indent:
            token->type = settled_by
            settled_by = 0
        else:
            token->type = 0
            dputs("\033[33m[CLIFF]\033[0m")

        indent_just_changed = 1
        return

    // indent just settled
    if look_ahead_tokens->size:
        next_token(token, 0)
        if indent_just_changed:
            if token->kind == END_OF_LINE_TOKEN:
                token->type = 4
            else:
                token->kind = BLOCK_COMMENT_TOKEN
            indent_just_changed = 0
        return

    // indent settled before
    next_token(token, 0)
    switch:
        token->kind
    case END_OF_LINE_TOKEN:
        if !token->type:
            fallthrough
    case MULTILINE_COMMENT_TOKEN:
        indent_settled = 0
        goto hell
    return


void look_ahead_queue(char action):
    if action == INIT:
        look_ahead_tokens = init()
    else:
        destroy(look_ahead_tokens)


int *strchr_i(register const int *s, int c):
    repeat *s++:
        if *s == c:
            return (int *)s
    return NULL


size_t strlen_i(const int *s):
    size_t i = -1
    while s[++i]:
        pass
    return i
