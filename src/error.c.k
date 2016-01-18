#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "input.h"
#include "token.h"
#include "error.h"

jmp_buf exception


void throw(int error_code, char *message, Token *token):
    "Report an error, then leave the current file or terminate the program."
    if token:
        int scanned = 0
        char *cursor = line
        fprintf(
            stderr, "\033[36;1m%s:\033[32;1m%d:%d: \033[31;1m%s\033[0m\n",
            file_name, token->row, token->column, message
        )
        while scanned < token->row:
            if *++cursor == '\n':
                scanned++

        scanned = 0
        while scanned++ < token->column:
            putc(*cursor++, stderr)
        fprintf(stderr, "\033[33;1m%s\033[0m", token->str)

        cursor += strlen(token->str)
        while *cursor && *cursor != '\n':
            putc(*cursor++, stderr)
        fprintf(stderr, "\033[0m\n%*s\n", token->column, "^");
    else:
        fprintf(stderr,
            "\033[36;1m%s: \033[31;1m%s\033[0m\n", file_name, message)

    if line:
        free(line)
        line = NULL

    // parsing error
    if error_code > 10:
        longjmp(exception, error_code)

    // runtime error
    else:
        exit(error_code)
