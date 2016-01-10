#ifndef TRANSLATOR_H_INCLUDED
#define TRANSLATOR_H_INCLUDED

typedef enum TranslatorStatus{
    INITIAL_STATUS,
    AFTER_KEYWORD,
    BEFORE_COLON,
    BEFORE_INDENT,
    INLINE_STATEMENT,
    BEFORE_UNINDENT,
    PREPROCESSOR
} TranslatorStatus;

typedef enum BlockStatus{
    UNKNOWN_BLOCK,
    FUNCTION_BLOCK,
    IF_BLOCK,
    ELIF_BLOCK,
    ELSE_BLOCK,
    WHILE_BLOCK,
    REPEAT_BLOCK,
    SWITCH_BLOCK,
    CASE_BLOCK,
    DEFAULT_BLOCK,
    ENUM_BLOCK,
    STRUCT_BLOCK
} BlockStatus;

void parse_file(void);

#endif /* TRANSLATOR_H_INCLUDED */
