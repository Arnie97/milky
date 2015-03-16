#include <stdio.h>
#include <stdlib.h>

#include "input.h"
#include "token.h"
#include "error.h"

void
throw(int error_code, char *message, Token *token)
{
    if (token != NULL) {
        fprintf(stderr, "\n%s:%d:%d: %s\n",
            file_name, token->row, token->column, message);
    } else {
        fprintf(stderr, "\n%s: %s\n", file_name, message);
    }
    exit(error_code);
}
