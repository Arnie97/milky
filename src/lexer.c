#include <stdio.h>
#include <string.h>
#include <ctype.h>

#include "input.h"
#include "token.h"
#include "keyword.h"
#include "error.h"
#include "lexer.h"

#define append { token->str[pos_in_token++] = current_char; line_pos++; }
#define subtract { token->str[--pos_in_token] = '\0'; line_pos--; }
#define retpos { return pos_in_token; }

static unsigned int line_start_pos, row = 1;

int
get_token(Token *token)
{
    int pos_in_token = 0;
    char last_char, current_char, next_char;

    token->kind = END_OF_FILE_TOKEN;
    token->row = row;
    token->column = line_pos - line_start_pos;

    while ((current_char = line[line_pos]) != '\0') {
        last_char = line[line_pos - 1];
        next_char = line[line_pos + 1];

        if (pos_in_token >= MAX_TOKEN_SIZE) {
            throw(11, "Token too long", token);
        }
        if (isspace(current_char)) {
            if (current_char == '\n') {
                row++;
                line_start_pos = line_pos;
                append;
                if (last_char == '\\') {
                    token->kind = ESCAPED_LINE_TOKEN;
                    retpos;
                }
                if (token->kind == STRING_TOKEN) {
                    token->kind = MULTILINE_STRING_TOKEN;
                    continue;
                }
                if (token->kind == BLOCK_COMMENT_TOKEN) {
                    token->kind = MULTILINE_COMMENT_TOKEN;
                    continue;
                }
                token->kind = END_OF_LINE_TOKEN;
                retpos;
            }
            append;
            continue;
        }

        append;
        switch (token->kind) {
        case CHAR_TOKEN:
            if (last_char != '\\' && current_char == '\'') {
                retpos;
            }
            continue;
        case STRING_TOKEN:
        case MULTILINE_STRING_TOKEN:
            if (last_char != '\\' && current_char == '"') {
                retpos;
            }
            continue;
        case BLOCK_COMMENT_TOKEN:
        case MULTILINE_COMMENT_TOKEN:
            if (last_char == '*' && current_char == '/') {
                retpos;
            }
            continue;
        case LINE_COMMENT_TOKEN:
            if (next_char == '\n') {
                retpos;
            }
            continue;
        }

        if (current_char == '/') {
            switch (next_char) {
            case '/':
                token->kind = LINE_COMMENT_TOKEN;
                continue;
            case '*':
                token->kind = BLOCK_COMMENT_TOKEN;
                continue;
            }
        }

        if (isalnum(current_char) || current_char == '_') {
            if (isalnum(next_char) || next_char == '_') {
                continue;
            }
            token->str[pos_in_token] = '\0';
            for (int type = sizeof(keywords) / sizeof(char *) - 1; type >= 0; type--) {
                if (strcmp(token->str, keywords[type]) == 0) {
                    token->kind = KEYWORD_TOKEN;
                    token->type = type;
                    retpos;
                }
            }
            token->kind = IDENTIFIER_TOKEN;
            retpos;
        }
        subtract;

        switch (current_char) {
        case '-':
            if (next_char == '>') {
                token->kind = OPERATOR_TOKEN;
                append;
                current_char = next_char;
                break;
            }
            /* fallthrough; */
        case '+':
            if (current_char == next_char) {
                token->kind = ASSIGNMENT_TOKEN;
                append;
                // current_char = next_char;
                break;
            }
            /* fallthrough; */
        case '&': case '|':
            if (current_char == next_char) {
                token->kind = OPERATOR_TOKEN;
                append;
                // current_char = next_char;
                break;
            }
            /* fallthrough; */
        case '*': case '/': case '^': case '%':
            if (next_char == '=') {
                token->kind = ASSIGNMENT_TOKEN;
                append;
                current_char = next_char;
                break;
            }
            /* fallthrough; */
        case '~':
            token->kind = OPERATOR_TOKEN;
            break;
        case '=': case '!': case '<': case '>':
            if (next_char != '=') {
                if (current_char == '=') {
                    token->kind = ASSIGNMENT_TOKEN;
                    break;
                } else if (current_char == '!') {
                    token->kind = OPERATOR_TOKEN;
                    break;
                } else if (current_char == next_char) {
                    token->kind = OPERATOR_TOKEN;
                    append;
                    // current_char = next_char;
                    break;
                }
            } else {
                append;
                current_char = next_char;
            }
            token->kind = COMPARISON_TOKEN;
            break;
        case ':':
            if (current_char == next_char) {
                token->kind = SCOPE_TOKEN;
                append;
                // current_char = next_char;
                break;
            }
            /* fallthrough; */
        case '(': case ')': case '[': case ']':
        case '{': case '}': case '.': case ',':
        case '#': case '?': case ';':
            token->kind = current_char;
            break;
        case '\'':
            token->kind = CHAR_TOKEN;
            append;
            continue;
        case '\"':
            token->kind = STRING_TOKEN;
            append;
            continue;
        }
        append;
        retpos;
    }
    return 0;
}

void
get_whitespace(Token *token, int pos_in_token)
{
    char current_char;
    while ((current_char = line[line_pos]) != '\0') {
        if (pos_in_token >= MAX_TOKEN_SIZE) {
            throw(12, "Whitespace too long", token);
        }
        if (!isspace(current_char) || current_char == '\n') {
            break;
        }
        append;
    }
    token->str[pos_in_token] = '\0';
}
