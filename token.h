#ifndef TOKEN_H_INCLUDED
#define TOKEN_H_INCLUDED

typedef enum {
    BAD_TOKEN,
    IDENTIFIER_TOKEN,
    KEYWORD_TOKEN,
    CHAR_TOKEN,
    STRING_TOKEN,
    COMMENT_TOKEN,

    INDENT_TOKEN,
    UNINDENT_TOKEN,
    END_OF_LINE_TOKEN,
    ESCAPED_LINE_TOKEN,

    OPERATOR_TOKEN,
    ASSIGNMENT_TOKEN,
    COMPARISON_TOKEN,

    LEFT_PAREN_TOKEN = '(',   RIGHT_PAREN_TOKEN = ')',
    LEFT_BRACKET_TOKEN = '[', RIGHT_BRACKET_TOKEN = ']',
    LEFT_BRACE_TOKEN = '{',   RIGHT_BRACE_TOKEN = '}',
    DOT_TOKEN = '.',
    COMMA_TOKEN = ',',
    EXCLAMATION_TOKEN = '!',
    QUESTION_TOKEN = '?',
    COLON_TOKEN = ':',
    SEMICOLON_TOKEN = ';',
    SHARP_TOKEN = '#'
} TokenKind;

#define MAX_TOKEN_SIZE (100)
#define LINE_BUF_SIZE (1000)
#define MAX_INDENTATION_LEVEL (20)

typedef struct {
    TokenKind kind;
    char str[MAX_TOKEN_SIZE];
} Token;

int get_token(Token *token);

#endif /* TOKEN_H_INCLUDED */
