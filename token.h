#ifndef TOKEN_H_INCLUDED
#define TOKEN_H_INCLUDED

typedef enum {
    BAD_TOKEN,
    IDENTIFIER_TOKEN,
    KEYWORD_TOKEN,
    CHAR_TOKEN,
    STRING_TOKEN,
    MULTILINE_STRING_TOKEN,
    LINE_COMMENT_TOKEN,
    BLOCK_COMMENT_TOKEN,
    MULTILINE_COMMENT_TOKEN,

    INDENT_TOKEN,
    UNINDENT_TOKEN,
    END_OF_LINE_TOKEN,
    ESCAPED_LINE_TOKEN,

    OPERATOR_TOKEN,
    ASSIGNMENT_TOKEN,
    COMPARISON_TOKEN,
    SCOPE_TOKEN,

    LEFT_PAREN_TOKEN = '(',   RIGHT_PAREN_TOKEN = ')',
    LEFT_BRACKET_TOKEN = '[', RIGHT_BRACKET_TOKEN = ']',
    LEFT_BRACE_TOKEN = '{',   RIGHT_BRACE_TOKEN = '}',
    DOT_TOKEN = '.',
    COMMA_TOKEN = ',',
    QUESTION_TOKEN = '?',
    COLON_TOKEN = ':',
    SEMICOLON_TOKEN = ';',
    SHARP_TOKEN = '#'
} TokenKind;

#define MAX_TOKEN_SIZE (100)

typedef struct {
    TokenKind kind;
    char type;
    char str[MAX_TOKEN_SIZE];
} Token;

static char *keywords[14] = {
    "if",
    "else",
    "elif",
    "for",
    "do",
    "while",
    "repeat",
    "switch",
    "case",
    "default",
    "fallthrough",
    "pass",
    "enum",
    "struct"
};

#endif /* TOKEN_H_INCLUDED */
