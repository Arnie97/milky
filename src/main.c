#include <stdio.h>
#include <string.h>

#include "input.h"
#include "translator.h"

char line[LINE_BUF_SIZE] = "~";
int line_pos = 1;
char *file_name = NULL;

int
main(int argc, char **argv)
{
    if (argc == 1) {
        fprintf(stderr, "No input files.\n");
        return 5;
    }
    file_name = argv[1];
    FILE *fp = fopen(file_name, "r");
    if (fp == NULL) {
        fprintf(stderr, "Test file not found!\n");
        return 6;
    }
    char buffer[LINE_BUF_SIZE];
    while (fgets(buffer, LINE_BUF_SIZE, fp) != NULL) {
        strcat(line, buffer);
    }
    fclose(fp);
    parse_file();
    return 0;
}
