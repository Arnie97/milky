#include <stdio.h>
#include <string.h>

#include "token.h"
#include "queue.h"
#include "error.h"
#include "lexer.h"
#include "indent.h"

#define MAX_INDENTATION_LEVEL (20)

static Queue *look_ahead_tokens

static int *strchr_i(const int *s, int c)
static size_t strlen_i(const int *s)


static void get_escaped(Token *token):
    "Recognize colons in ?: operators and line breaks in brackets."
    static int ternary_expressions, unclosed_brackets
    switch:
        token->family
    case '(', '[', '{':
        unclosed_brackets++
    case ')', ']', '}':
        unclosed_brackets--
    case '?':
        ternary_expressions++
    case ':':
        if ternary_expressions:
            ternary_expressions--
            token->family = ESCAPED_COLON_TOKEN
    case END_OF_LINE_TOKEN:
        if unclosed_brackets:
            token->type = IN_BRACKETS
    case MULTILINE_COMMENT_TOKEN:
        if unclosed_brackets:
            token->family = BLOCK_COMMENT_TOKEN


static inline void next_token(Token *token, char force_look_ahead):
    "Fetch a token from the look-ahead queue."
    if !force_look_ahead && look_ahead_tokens->size:
        dequeue(look_ahead_tokens, token)
    else:
        get_whitespace(token, get_token(token))
        get_escaped(token)


static inline void store_token(Token *token):
    "Push a token into the look-ahead queue."
    enqueue(look_ahead_tokens, *token)


void get_indent(Token *token):
    "Analyze indent changes,
        then insert (un)indent tokens into the token stream."
    static char settled_by, indent_just_changed
    static int indent_settled, current_indent
    static int indents[MAX_INDENTATION_LEVEL] = { 0 }
    char first_new_line = 1

    while !indent_settled:
        next_token(token, 1)
        hell => switch:
            token->family

        case MULTILINE_COMMENT_TOKEN:  // empty line ending with MULTILINE
            current_indent = strrchr(token->str, '\n') - token->str + 1
            current_indent = strlen(token->str) - current_indent
            if first_new_line:
                first_new_line = 0
            else:
                token->family = BLOCK_COMMENT_TOKEN
            store_token(token)
            continue

        case END_OF_LINE_TOKEN:  // empty line too
            if token->type:
                throw(21, "Escaping an empty line", token)
            else:
                current_indent = -1

            if first_new_line:
                first_new_line = 0
            else:
                token->type = REDUNDANT_LINE

        case LINE_COMMENT_TOKEN:
            token->type = 1

        case BLOCK_COMMENT_TOKEN:
            pass

        case SHARP_TOKEN:
            while (
                !(token->family == END_OF_LINE_TOKEN && !token->type) &&
                token->family != MULTILINE_COMMENT_TOKEN &&
                token->family != END_OF_FILE_TOKEN
            ):
                if token->family == KEYWORD_TOKEN:
                    token->family = IDENTIFIER_TOKEN
                store_token(token)
                next_token(token, 1)

            if token->family == END_OF_FILE_TOKEN:
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
        token->family = INDENT_TOKEN
        token->str[0] = '\0'
        dprintf((BRIGHT + GREEN, "[i%d->%d]", last_indent, current_indent))
        indents[indent_levels] = current_indent

        token->type = settled_by
        settled_by = 0

        indent_just_changed = 1
        return

    if indent_change < 0:
        token->family = UNINDENT_TOKEN
        token->str[0] = '\0'
        if !strchr_i(indents, current_indent):
            throw(22, "Unindent does not match any outer indentation level", token)
        dprintf((BRIGHT + RED, "[u%d->%d]", last_indent, current_indent))
        indents[indent_levels - 1] = 0

        if indents[indent_levels - 2] == current_indent:
            token->type = settled_by
            settled_by = 0
        else:
            token->type = PASS
            dprintf((RED, "[cliff]"))

        indent_just_changed = 1
        return

    // indent just settled
    if look_ahead_tokens->size:
        next_token(token, 0)
        if indent_just_changed:
            if token->family == END_OF_LINE_TOKEN:
                token->type = INDENT_CHANGED
            else:
                token->family = BLOCK_COMMENT_TOKEN
            indent_just_changed = 0
        return

    // indent settled before
    next_token(token, 0)
    switch:
        token->family
    case END_OF_LINE_TOKEN:
        if !token->type:
            fallthrough
    case MULTILINE_COMMENT_TOKEN:
        indent_settled = 0
        goto hell
    return


void look_ahead_queue(char action):
    "Create or destroy the look-ahead queue."
    if action == INIT:
        look_ahead_tokens = init()
    else:
        destroy(look_ahead_tokens)


static inline int *strchr_i(register const int *s, int c):
    "Standard library 'strchr' for int arrays."
    repeat *s++:
        if *s == c:
            return (int *)s
    return NULL


static inline size_t strlen_i(const int *s):
    "Standard library 'strlen' for int arrays."
    size_t i = -1
    while s[++i]:
        pass
    return i
