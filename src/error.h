#ifndef ERROR_H_INCLUDED
#define ERROR_H_INCLUDED

#include <setjmp.h>

#ifdef _DEBUG
    #define dprintf(x) printf x
    #define dputs(x) puts(x)
#else
    #define dprintf(x)
    #define dputs(x)
#endif

extern jmp_buf exception;

void throw(int error_code, char *message, Token *token);

#endif /* ERROR_H_INCLUDED */
