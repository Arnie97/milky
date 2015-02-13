#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include "token.h"

#define append { token->str[pos_in_token++] = current_char; line_pos++; }
#define retpos { return pos_in_token; }

static char line[LINE_BUF_SIZE] = "~";
static int line_pos;
static char indents[MAX_INDENTATION_LEVEL] = { 0 }, current_indent;

int
get_token(Token *token)
{
    int pos_in_token = 0;
    char last_char, current_char, next_char, *outer_indent;

    char last_indent = strlen(indents);
    if (last_indent != 0) {
        last_indent = indents[last_indent - 1];
    }
    char indent_change = current_indent - last_indent;
    if (indent_change > 0) {
        token->kind = INDENT_TOKEN;
        printf("INDENT>>%d\n", indent_change);
        indents[strlen(indents)] = current_indent;
        retpos;
    }
    if (indent_change < 0) {
        token->kind = UNINDENT_TOKEN;
        if (current_indent == indents[strlen(indents) - 2]) {
            ;
        } else if ((outer_indent = strchr(indents, current_indent)) != NULL) {
            current_indent = last_indent;
        } else {
            fprintf(stderr, "Unindent does not match any outer indentation level.\n");
            exit(3);
        }
        printf("UNINDENT<<%d\n", -indent_change);
        indents[strlen(indents) - 1] = 0;
        retpos;
    }

    token->kind = BAD_TOKEN;

    while ((current_char = line[line_pos]) != '\0') {
        last_char = line[line_pos - 1];
        next_char = line[line_pos + 1];

        if (pos_in_token >= MAX_TOKEN_SIZE) {
            fprintf(stderr, "Token too long.\n");
            exit(1);
        }
        if (isspace(current_char)) {
            if (current_char == '\n') {
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
                current_indent = 0;
                retpos;
            }
            append;
            continue;
        }
        if (token->kind == CHAR_TOKEN) {
            append;
            if (last_char != '\\' && current_char == '\'') {
                retpos;
            } else {
                continue;
            }
        }
        if (token->kind == STRING_TOKEN) {
            append;
            if (last_char != '\\' && current_char == '"') {
                retpos;
            } else {
                continue;
            }
        }
        if (token->kind == BLOCK_COMMENT_TOKEN || token->kind == MULTILINE_COMMENT_TOKEN) {
            append;
            if (last_char == '*' && current_char == '/') {
                retpos;
            } else {
                continue;
            }
        }
        if (token->kind == LINE_COMMENT_TOKEN) {
            append;
            if (next_char == '\n') {
                retpos;
            }
            continue;
        }

        if (current_char == '/') {
            switch (next_char) {
            case '/':
                token->kind = LINE_COMMENT_TOKEN;
                append;
                continue;
            case '*':
                token->kind = BLOCK_COMMENT_TOKEN;
                append;
                continue;
            }
        }

        if (isalnum(current_char) || current_char == '_') {
            append;
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
        case '(': case ')': case '[': case ']':
        case '{': case '}': case '.': case ',':
        case '#': case '?': case ':': case ';':
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
}

void
get_whitespace(Token *token, int pos_in_token)
{
    char current_char;
    if (token->kind == MULTILINE_COMMENT_TOKEN) {
        current_indent = pos_in_token - (int)(strrchr(token->str, '\n') - token->str + 1) / sizeof(char);
    }
    while ((current_char = line[line_pos]) != '\0') {
        if (pos_in_token >= MAX_TOKEN_SIZE) {
            fprintf(stderr, "Whitespace too long.\n");
            exit(2);
        }
        if (!isspace(current_char) || current_char == '\n') {
            break;
        }
        if (token->kind == END_OF_LINE_TOKEN || token->kind == MULTILINE_COMMENT_TOKEN) {
            current_indent++;
        }
        append;
    }
    token->str[pos_in_token] = '\0';
}

#if 1
void
parse_line(void)
{
    Token token;
    line_pos = 1;
    printf("start!\n");
    for (;;) {
        int prev_pos = line_pos;
        get_whitespace(&token, get_token(&token));
        printf(token.kind > 0x20?
            "line_pos..%d->%d   kind..%c    str..[%s]":
            "line_pos..%d->%d   kind..%d    str..[%s]",
            prev_pos, line_pos, token.kind, token.str);
        getchar();
        if (token.kind == SHARP_TOKEN) {
            break;
        }
    }
}

int
main(int argc, char **argv)
{
    FILE *fp = fopen("foobar.milk", "r");
    if (fp == NULL) {
        fprintf(stderr, "Test file not found!\n");
        return 1;
    }
    char buffer[LINE_BUF_SIZE];
    while (fgets(buffer, LINE_BUF_SIZE, fp) != NULL) {
        strcat(line, buffer);
    }
    fclose(fp);
    parse_line();
    return 0;
}
#endif
