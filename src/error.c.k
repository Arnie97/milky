#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#endif

#include "input.h"
#include "token.h"
#include "error.h"

jmp_buf exception


int fg_color(FILE *stream, int color):
    "Cross-platform solution to change foreground text color on a console."
#ifndef _WIN32
    if color == RESET:
        fputs("\033[0m", stream)
    else:
        int bright_attr = color & BRIGHT? 1: 0
        int color_attr = (color & WHITE) + 30
        fprintf(stream, "\033[%d;%dm", bright_attr, color_attr)
#else
    HANDLE console = GetStdHandle(
        stream == stdout? STD_OUTPUT_HANDLE: STD_ERROR_HANDLE
    )
    if console == INVALID_HANDLE_VALUE:
        return 1
    CONSOLE_SCREEN_BUFFER_INFO csbi
    if !GetConsoleScreenBufferInfo(console, &csbi):
        return 2

    if color == RESET:
        color = WHITE
    color |= csbi.wAttributes & 240
    if !SetConsoleTextAttribute(console, color):
        return 3
#endif
    return 0


int cprintf(int color, const char *format, ...):
    "A simple wrapper for fg_color() and fprintf()."
    fg_color(stderr, color)
    va_list args
    va_start(args, format)
    vfprintf(stderr, format, args)
    va_end(args)
    return fg_color(stderr, RESET)


void throw(int error_code, char *message, Token *token):
    "Report an error, then leave the current file or terminate the program."
    cprintf(BRIGHT + CYAN, "%s:", file_name)
    if token:
        cprintf(BRIGHT + GREEN, "%d:%d:", token->row, token->column)
    cprintf(BRIGHT + RED, " %s\n", message)

    if token:
        int scanned = 0
        char *cursor = line
        while scanned < token->row:
            if *++cursor == '\n':
                scanned++

        scanned = 0
        while scanned++ < token->column:
            putc(*cursor++, stderr)
        cprintf(BRIGHT + YELLOW, "%s", token->str)

        cursor += strlen(token->str)
        while *cursor && *cursor != '\n':
            putc(*cursor++, stderr)
        cprintf(BRIGHT + WHITE, "\n%*s\n", token->column, "^");

    if line:
        free(line)
        line = NULL

    // parsing error
    if error_code > 10:
        longjmp(exception, error_code)

    // runtime error
    else:
        exit(error_code)
