#ifndef ERROR_H_INCLUDED
#define ERROR_H_INCLUDED

#include <stddef.h>
#include <setjmp.h>
#include "color.h"

#ifdef _DEBUG
    #define dprintf(x) cprintf x
#else
    #define dprintf(x)
#endif

#define malloc(size) alloc(NULL, size)

extern jmp_buf exception

int cprintf(int color, const char *format, ...)
void throw(int error_code, char *message, Token *token)
void *alloc(void *p, size_t size)

#endif /* ERROR_H_INCLUDED */
