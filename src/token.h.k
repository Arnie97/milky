#ifndef TOKEN_H_INCLUDED
#define TOKEN_H_INCLUDED

// token families
enum TokenFamily:
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
    END_OF_FILE_TOKEN,

    OPERATOR_TOKEN,
    ASSIGNMENT_TOKEN,
    COMPARISON_TOKEN,
    SCOPE_TOKEN,
    GOTO_TAG_TOKEN,

    LEFT_PAREN_TOKEN = '(',   RIGHT_PAREN_TOKEN = ')',
    LEFT_BRACKET_TOKEN = '[', RIGHT_BRACKET_TOKEN = ']',
    LEFT_BRACE_TOKEN = '{',   RIGHT_BRACE_TOKEN = '}',
    DOT_TOKEN = '.',
    COMMA_TOKEN = ',',
    QUESTION_TOKEN = '?',
    COLON_TOKEN = ':',
    ESCAPED_COLON_TOKEN = '"',
    SEMICOLON_TOKEN = ';',
    SHARP_TOKEN = '#'

// token types
#define IF              0x00
#define ELIF            0x01
#define ELSE            0x02
#define FOR             0x03
#define DO              0x04
#define WHILE           0x05
#define REPEAT          0x06
#define SWITCH          0x07
#define CASE            0x08
#define DEFAULT         0x09
#define FALLTHROUGH     0x0a
#define PASS            0x0b
#define ENUM            0x0c
#define STRUCT          0x0d
#define UNION           0x0e

#define NORMAL_LINE     0x00
#define LITERAL_ESCAPE  0x01
#define IN_BRACKETS     0x02
#define REDUNDANT_LINE  0x03
#define INDENT_CHANGED  0x04
#define BEFORE_COMMENT  0x05

#define MAX_TOKEN_SIZE (4096)

struct Token:
    TokenFamily family
    char type
    char str[MAX_TOKEN_SIZE]
    unsigned int row, column

#endif /* TOKEN_H_INCLUDED */
