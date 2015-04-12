#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "input.h"
#include "token.h"
#include "error.h"
#include "translator.h"

int line_pos = 1;
char *line = NULL, *file_name = "milky";
FILE *output;

int
main(int argc, char **argv)
{
    if (argc == 1) {
        throw(1, "No input files", NULL);
    }
    file_name = argv[1];
    output = stdout;
    FILE *fp = fopen(file_name, "r");
    if (fp == NULL) {
        throw(2, "Unable to open specified file", NULL);
    }

    char c = '~';
    int size = 0, i = 1;
    while ((c = fgetc(fp)) != EOF) {
        if (i > size - 4) {
            if ((line = realloc(line, size += BUFFER_SIZE)) == NULL) {
                throw(3, "Insufficient memory", NULL);
            }
        }
        line[i++] = c;
    }
    line[0] = '~';
    for (size = i + 3; i < size; line[i++] = '\0');
    fclose(fp);
    parse_file();
    free(line);
    return 0;
}
