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

static unsigned int line_start_pos, row


int get_token(Token *token):
    "Split the input stream into different types of tokens."
    int pos_in_token = 0
    char last_char, current_char, next_char, escaped

    token->kind = END_OF_FILE_TOKEN
    token->row = row
    token->column = line_pos - line_start_pos
    token->type = -1

    while (current_char = line[line_pos]) != '\0':
        last_char = line[line_pos - 1]
        next_char = line[line_pos + 1]
        if pos_in_token >= MAX_TOKEN_SIZE:
            throw(11, "Token too long", token)

        if isspace(current_char):
            if current_char == '\n':
                row++
                line_start_pos = line_pos
                switch:
                    token->kind
                case STRING_TOKEN:
                    token->kind = MULTILINE_STRING_TOKEN
                    fallthrough
                case MULTILINE_STRING_TOKEN:
                    if escaped:
                        escaped = 0
                    else:
                        token->str[pos_in_token++] = '\\'
                        token->str[pos_in_token++] = 'n'
                        token->str[pos_in_token++] = '\\'
                case BLOCK_COMMENT_TOKEN:
                    token->kind = MULTILINE_COMMENT_TOKEN
                case MULTILINE_COMMENT_TOKEN:
                    pass
                default:
                    token->kind = END_OF_LINE_TOKEN
                    token->type = (last_char == '\\') // escaped new line
                    append
                    retpos
            append
            continue
        append

        switch:
            token->kind
        case CHAR_TOKEN, STRING_TOKEN, MULTILINE_STRING_TOKEN:
            if escaped:
                escaped = 0
            elif current_char == '\\':
                escaped = 1
            elif token->kind == CHAR_TOKEN:
                if current_char == '\'':
                    retpos
            elif current_char == '"':
                retpos
            continue
        case BLOCK_COMMENT_TOKEN, MULTILINE_COMMENT_TOKEN:
            if last_char == '*' && current_char == '/':
                retpos
            continue
        case LINE_COMMENT_TOKEN:
            if next_char == '\n':
                retpos
            continue

        if current_char == '/':
            switch:
                next_char
            case '/':
                token->kind = LINE_COMMENT_TOKEN
                continue
            case '*':
                token->kind = BLOCK_COMMENT_TOKEN
                continue

        if isalnum(current_char) || current_char == '_':
            if isalnum(next_char) || next_char == '_':
                continue
            token->str[pos_in_token] = '\0'
            for int t = sizeof(keywords) / sizeof(char *) - 1; t >= 0; t--:
                if strcmp(token->str, keywords[t]) == 0:
                    token->kind = KEYWORD_TOKEN
                    token->type = t
                    retpos
            token->kind = IDENTIFIER_TOKEN
            retpos
        subtract

        switch:
            current_char
        case '\\':
            if next_char == '\n':
                line_pos++
                continue
            else:
                append
                throw(13, "Malformed escape sequence", token)
        case '-':
            if next_char == '>':
                token->kind = OPERATOR_TOKEN
                append
                current_char = next_char
            else:
                fallthrough
        case '+':
            if current_char == next_char:
                token->kind = ASSIGNMENT_TOKEN
                append
                // current_char = next_char
            else:
                fallthrough
        case '&', '|':
            if current_char == next_char:
                token->kind = OPERATOR_TOKEN
                append
                // current_char = next_char
            else:
                fallthrough
        case '*', '/', '^', '%':
            if next_char == '=':
                token->kind = ASSIGNMENT_TOKEN
                append
                current_char = next_char
            else:
                fallthrough
        case '~':
            token->kind = OPERATOR_TOKEN
        case '=':
            if next_char == '>':
                token->kind = GOTO_TAG_TOKEN
                append
                current_char = next_char
            else:
                fallthrough
        case '!', '<', '>':
            if next_char != '=':
                if current_char == '=':
                    token->kind = ASSIGNMENT_TOKEN
                    break
                elif current_char == '!':
                    token->kind = OPERATOR_TOKEN
                    break
                elif current_char == next_char:
                    token->kind = OPERATOR_TOKEN
                    append
                    // current_char = next_char
                    break
            else:
                append
                current_char = next_char
            token->kind = COMPARISON_TOKEN
        case ':':
            if current_char == next_char:
                token->kind = SCOPE_TOKEN
                append
                // current_char = next_char
            else:
                fallthrough
        case '(', ')', '[', ']', '{', '}', '.', ',', '#', '?', ';':
            token->kind = current_char
        case '\'':
            escaped = 0
            token->kind = CHAR_TOKEN
            append
            continue
        case '\"':
            escaped = 0
            token->kind = STRING_TOKEN
            append
            continue
        append
        retpos
    return 0


void get_whitespace(Token *token, int pos_in_token):
    "Meld white-space characters into the previous token."
    char current_char
    while (current_char = line[line_pos]) != '\0':
        if pos_in_token >= MAX_TOKEN_SIZE:
            throw(12, "Whitespace too long", token)
        if !isspace(current_char) || current_char == '\n':
            break
        append
    token->str[pos_in_token] = '\0'
