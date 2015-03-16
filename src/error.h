#ifndef ERROR_H_INCLUDED
#define ERROR_H_INCLUDED

void throw(int error_code, char *message, Token *token);

/*
test.c:14:0: error: unterminated argument list invoking macro "debug"
test.c:11:5: error: 'debug' undeclared (first use in this function)
     debug(("x%dy%d", 1, 2)
     ^
*/

#endif /* ERROR_H_INCLUDED */
