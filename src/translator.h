#ifndef TRANSLATOR_H_INCLUDED
#define TRANSLATOR_H_INCLUDED

#define MAX_LOOK_AHEAD_TOKENS (20)
#define MAX_INDENT_LEVELS (20)

typedef enum {
    INITIAL_STATUS,
    AFTER_KEYWORD,
    BEFORE_COLON,
    BEFORE_INDENT,
    INLINE_STATEMENT,
    PREPROCESSOR,
    BEGIN_OF_LINE
} TranslatorStatus;

typedef enum {
    FUNCTION,
    IF,
    ELSE,
    SWITCH,
    CASE,
    FALLTHROUGH,
    REPEAT,
    STRUCT
} IndentStatus;

void parse_file(void);

#endif /* TRANSLATOR_H_INCLUDED */
