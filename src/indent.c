#include <stdio.h>
#include <string.h>

#include "token.h"
#include "queue.h"
#include "error.h"
#include "lexer.h"
#include "indent.h"

Queue *look_ahead_tokens;

static void
get_escaped(Token *token)
{
    static char ternary_expressions, unclosed_brackets;
    switch (token->kind) {
    case '(': case '[': case '{':
        unclosed_brackets++;
        break;
    case ')': case ']': case '}':
        unclosed_brackets--;
        break;
    case '?':
        ternary_expressions++;
        break;
    case ':':
        if (ternary_expressions) {
            ternary_expressions--;
            token->kind = ESCAPED_COLON_TOKEN;
        }
        break;
    case END_OF_LINE_TOKEN:
        if (unclosed_brackets) {
            token->kind = ESCAPED_LINE_TOKEN;
        }
        break;
    case MULTILINE_COMMENT_TOKEN:
        if (unclosed_brackets) {
            token->kind = BLOCK_COMMENT_TOKEN;
        }
        break;
    }
}

static inline void
next_token(Token *token, char force_look_ahead)
{
    if (!force_look_ahead && look_ahead_tokens->size) {
        dequeue(look_ahead_tokens, token);
    } else {
        get_whitespace(token, get_token(token));
        get_escaped(token);
    }
}

static inline void
store_token(Token *token)
{
    enqueue(look_ahead_tokens, *token);
}

void
get_indent(Token *token)
{
    static char indent_settled, current_indent;
    static char indents[MAX_INDENTATION_LEVEL] = { 0 };

    while (!indent_settled) {
        next_token(token, 1);
    hell:
        switch (token->kind) {
        case MULTILINE_COMMENT_TOKEN: // empty line ending with MULTILINE
            current_indent = strlen(token->str) - (int)(strrchr(token->str, '\n') - token->str + 1) / sizeof(char);
            store_token(token);
            continue;
        case END_OF_LINE_TOKEN: // empty line too
            current_indent = -1;
            /* fallthrough; */
        case LINE_COMMENT_TOKEN:
        case BLOCK_COMMENT_TOKEN:
            current_indent += strlen(token->str);
            store_token(token);
            continue;
        case ESCAPED_LINE_TOKEN:
            throw(21, "Escaping an empty line", token);
        default:
            indent_settled = 1;
            store_token(token);
        }
    }

    // indent just settled, token not inserted
    char indent_levels = strlen(indents);
    char last_indent = indent_levels? indents[indent_levels - 1]: 0;
    char indent_change = current_indent - last_indent;
    if (indent_change > 0) {
        token->kind = INDENT_TOKEN;
        token->str[0] = '\0';
        dprintf(("\033[32m[IN %d->%d]\033[0m", last_indent, current_indent));
        indents[indent_levels] = current_indent;
        return;
    }
    if (indent_change < 0) {
        token->kind = UNINDENT_TOKEN;
        token->str[0] = '\0';
        if (strchr(indents, current_indent) == NULL) {
            throw(22, "Unindent does not match any outer indentation level", token);
        }
        dprintf(("\033[33m[UN %d->%d]\033[0m", last_indent, current_indent));
        indents[indent_levels - 1] = 0;
        return;
    }

    // indent just settled
    if (look_ahead_tokens->size) {
        next_token(token, 0);
        return;
    }

    // indent settled before
    next_token(token, 0);
    switch (token->kind) {
    case END_OF_LINE_TOKEN:
    case MULTILINE_COMMENT_TOKEN:
        indent_settled = 0;
        goto hell;
    default:
        return;
    }
}

void
look_ahead_queue(char action) {
    if (action == INIT) {
        look_ahead_tokens = init();
    } else {
        destroy(look_ahead_tokens);
    }
}
