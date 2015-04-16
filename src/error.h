#ifndef ERROR_H_INCLUDED
#define ERROR_H_INCLUDED

#ifdef _DEBUG
    #define dprintf(x) printf x
    #define dputs(x) puts(x)
#else
    #define dprintf(x)
    #define dputs(x)
#endif

void throw(int error_code, char *message, Token *token);

/*
test.c:14:0: error: unterminated argument list invoking macro "debug"
test.c:11:5: error: 'debug' undeclared (first use in this function)
     debug(("x%dy%d", 1, 2)
     ^
*/

#endif /* ERROR_H_INCLUDED */
