#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include "token.h"
#define append { token->str[pos_in_token++] = current_char; line_pos++; }
#define terminate { token->str[pos_in_token] = '\0'; }

static char line[LINE_BUF_SIZE] = "~";
static int line_pos;

typedef enum {
    INITIAL_STATUS,
    BEGIN_OF_LINE,
    IN_STRING_LITERAL,
    IN_CHAR_LITERAL,
    IN_BLOCK_COMMENT,
    IN_LINE_COMMENT,
    AFTER_DIVISOR
} LexerStatus;

void
get_token(Token *token)
{
    int pos_in_token = 0;
    static LexerStatus status = INITIAL_STATUS;
    char last_char, current_char, next_char;
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
                if (status == IN_LINE_COMMENT) { // Should return a separate EOL instead, modify :96
                    status = INITIAL_STATUS;
                    token->kind = COMMENT_TOKEN;
                    append;
                    terminate;
                    return;
                }
                if (status == IN_BLOCK_COMMENT) {
                    append;
                    continue;
                }
                status = BEGIN_OF_LINE;
                token->kind = END_OF_LINE_TOKEN;
                append;
                terminate;
                return;
            }
            if (status == BEGIN_OF_LINE) { // Warning: If statement with assignment
                // Test if indent or dedent.
            }
            append;
            continue;
        }
        if (status == IN_CHAR_LITERAL) {
            append;
            if (last_char != '\\' && current_char == '\'') {
                status = INITIAL_STATUS;
                token->kind = CHAR_TOKEN;
                terminate;
                return;
            } else {
                continue;
            }
        }
        if (status == IN_STRING_LITERAL) {
            append;
            if (last_char != '\\' && current_char == '"') {
                status = INITIAL_STATUS;
                token->kind = STRING_TOKEN;
                terminate;
                return;
            } else {
                continue;
            }
        }
        if (status == IN_BLOCK_COMMENT) {
            append;
            if (last_char == '*' && current_char == '/') {
                status = INITIAL_STATUS;
                token->kind = COMMENT_TOKEN;
                terminate;
                return;
            } else {
                continue;
            }
        }
        if (status == IN_LINE_COMMENT) {
            append;
            continue;
        }
        
        if (current_char == '/') {
            switch (next_char) {
            case '/':
                status = IN_LINE_COMMENT;
                append;
                continue;
            case '*':
                status = IN_BLOCK_COMMENT;
                append;
                continue;
            case '=':
                token->kind = OPERATOR_TOKEN;
                strcpy("/=", token->str);
                line_pos += 2;
                return;
            }
        }

        if (isalnum(current_char) || current_char == '_') {
            append;
            if (isalnum(next_char) || next_char == '_') {
                continue;
            }
            token->kind = IDENTIFIER_TOKEN;
            terminate;
            return;
        }

        switch (current_char) {
        case '+': case '-': case '*': case '/':
            token->kind = OPERATOR_TOKEN;
            break;
        case '=':
            token->kind = ASSIGNMENT_TOKEN;
            break;
        case '(': case ')': case '[': case ']':
        case '{': case '}': case '.': case ',':
        case '!': case '?': case ':': case ';':
        case '#':
            token->kind = current_char;
            break;
        case '\'':
            status = IN_CHAR_LITERAL;
            append;
            continue;
        case '\"':
            status = IN_STRING_LITERAL;
            append;
            continue;
        }
        append;
        terminate;
        return;
    }
}

void
set_line(char *line)
{
    line = line;
    line_pos = 0;
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
        get_token(&token);
        printf(token.kind > 0x20?
            "line_pos..%d->%d....kind..%c....str..%s":
            "line_pos..%d->%d....kind..%d....str..%s",
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
