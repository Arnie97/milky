#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include "token.h"

static char *st_line;
static int st_line_pos;

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
    char last_char, current_char = '\0';
    token->kind = BAD_TOKEN;

    while (st_line[st_line_pos] != '\0') {
        last_char = st_line[st_line_pos - 1];
        current_char = st_line[st_line_pos];

        if (pos_in_token >= MAX_TOKEN_SIZE) {
            fprintf(stderr, "Token too long.\n");
            exit(1);
        }
        if (isspace(current_char)) {
            if (current_char == '\n') {
                if (status == IN_LINE_COMMENT) { // Should return a separate EOL instead, modify :96
                    status = INITIAL_STATUS;
                    token->kind = COMMENT_TOKEN;
                    token->str[pos_in_token++] = current_char;
                    token->str[pos_in_token] = '\0';
                    st_line_pos++;
                    return;
                }
                if (status == IN_BLOCK_COMMENT) {
                    token->str[pos_in_token++] = current_char;
                    st_line_pos++;
                    continue;
                }
                status = BEGIN_OF_LINE;
                token->kind = END_OF_LINE_TOKEN;
                token->str[pos_in_token++] = '\n';
                token->str[pos_in_token] = '\0';
                st_line_pos++;
                return;
            }
            if (status == BEGIN_OF_LINE) { // Warning: If statement with assignment
                // Test if indent or dedent.
            }
            token->str[pos_in_token++] = current_char;
            st_line_pos++;
            continue;
        }
        if (status == IN_CHAR_LITERAL) {
            token->str[pos_in_token++] = current_char;
            st_line_pos++;
            if (last_char != '\\' && current_char == '\'') {
                status = INITIAL_STATUS;
                token->kind = CHAR_TOKEN;
                token->str[pos_in_token] = '\0';
                return;
            } else {
                continue;
            }
        }
        if (status == IN_STRING_LITERAL) {
            token->str[pos_in_token++] = current_char;
            st_line_pos++;
            if (last_char != '\\' && current_char == '"') {
                status = INITIAL_STATUS;
                token->kind = STRING_TOKEN;
                token->str[pos_in_token] = '\0';
                return;
            } else {
                continue;
            }
        }
        if (status == IN_BLOCK_COMMENT) {
            token->str[pos_in_token++] = current_char;
            st_line_pos++;
            if (last_char == '*' && current_char == '/') {
                status = INITIAL_STATUS;
                token->kind = COMMENT_TOKEN;
                token->str[pos_in_token] = '\0';
                return;
            } else {
                continue;
            }
        }
        if (status == IN_LINE_COMMENT) {
            token->str[pos_in_token++] = current_char;
            st_line_pos++;
            continue;
        }
        
        if (last_char == '/') {
            if (current_char == '/') {
                status = IN_LINE_COMMENT;
                token->str[pos_in_token++] = '/';
                token->str[pos_in_token++] = '/';
                st_line_pos++;
                continue;
            } else if (current_char == '*') {
                status = IN_BLOCK_COMMENT;
                token->str[pos_in_token++] = '/';
                token->str[pos_in_token++] = '*';
                st_line_pos++;
                continue;
            } else if (current_char == '=') {
                token->kind = OPERATOR_TOKEN;
                token->str[0] = '/';
                token->str[1] = '=';
                token->str[2] = '\0';
                st_line_pos++;
                return;
            } else if (status == AFTER_DIVISOR) {
                status = INITIAL_STATUS;
            } else { // With fault around used slash.
                status = AFTER_DIVISOR;
                token->kind = OPERATOR_TOKEN;
                token->str[0] = '/';
                token->str[1] = '\0';
                return;
            }
        }
        if (current_char == '/') {
            st_line_pos++;
            continue;
        }

        switch (current_char) {
        case '+':
        case '-':
        case '*':
        case '/':
            token->kind = OPERATOR_TOKEN;
            break;
        case '(':
            token->kind = LEFT_PAREN_TOKEN;
            break;
        case ')':
            token->kind = RIGHT_PAREN_TOKEN;
            break;
        case '\'':
            status = IN_CHAR_LITERAL;
            token->str[pos_in_token++] = current_char;
            printf("CHR^\n");
            st_line_pos++;
            continue;
        case '\"':
            status = IN_STRING_LITERAL;
            token->str[pos_in_token++] = current_char;
            printf("STR^\n");
            st_line_pos++;
            continue;
        case '#':
            token->kind = SHARP_TOKEN;
            break;
        }
        token->str[pos_in_token++] = current_char;
        st_line_pos++;
        return;
    }
}

void
set_line(char *line)
{
    st_line = line;
    st_line_pos = 0;
}

#if 1
void
parse_line(void)
{
    Token token;
    st_line_pos = 0;
    printf("start!\n");
    for (;;) {
        int prev_pos = st_line_pos;
        get_token(&token);
        printf("st_line_pos..%d->%d....kind..%d....str..%s",
            prev_pos, st_line_pos, token.kind, token.str);
        getchar();
        if (token.kind == SHARP_TOKEN) {
            break;
        }
    }
}
#endif

#if 1
int
main(int argc, char **argv)
{
    //         (1+2) 'one + two \' @'    // comments
    //         "abc \" def" /* another */#
    st_line = "(1+2) 'one + two \\' @'    // comments\n\"abc \\\" def\" /* another */#";
    parse_line();
/*
    while (fgets(st_line, LINE_BUF_SIZE, stdin) != NULL) {
        parse_line();
    }

    return 0;
*/
}
#endif
