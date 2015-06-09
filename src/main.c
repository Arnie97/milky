#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "input.h"
#include "token.h"
#include "error.h"
#include "translator.h"

int line_pos;
char *line = NULL, *file_name = "milky";
FILE *output;
jmp_buf exception;

void
load_file(FILE *fp)
{
    int size = 0, i = 2;
    for (char c; (c = fgetc(fp)) != EOF; line[i++] = c) {
        if (i > size - 5) {
            if ((line = realloc(line, size += BUFFER_SIZE)) == NULL) {
                throw(3, "Insufficient memory", NULL);
            }
        }
    }
    line_pos = 1;
    line[0] = line[1] = '\n';
    line[i++] = '\n';
    for (size = i + 3; i < size; line[i++] = '\0');
}

void
open_file(const char *input_name, const char *output_name)
{
    dprintf(("%s >> %s\n", input_name, output_name));
    FILE *fp_in = fopen(input_name, "r");
    if (fp_in == NULL) {
        goto handler;
    } else {
        load_file(fp_in);
        fclose(fp_in);
    }

    FILE *fp_out = fopen(output_name, "w");
    if (fp_out == NULL) {
        goto handler;
    } else {
#ifdef _DEBUG
        output = stdout;
#else
        output = fp_out;
#endif
        if (!setjmp(exception)) {
            parse_file();
            dputs("Never here!");
        }
        fclose(fp_out);
    }
    return;

handler:
    throw(2, "Unable to open specified file", NULL);
}

int
main(int argc, char *argv[])
{
    int files_count = 0;
    char is_option = 1, *output_name = NULL, *name_ext;

    for (int i = 0; i < argc; i++) {
        if (is_option && strcmp(argv[i], "--")) { // separator before file names
            is_option = 0;
        } else if (argv[i][0] == '-') { // treat as an option
            if (strcmp(argv[i], "-o") == 0) {
                if (++i >= argc) {
                    throw(4, "Missing filename after '-o'", NULL);
                } else if (output_name != NULL) {
                    throw(5, "Cannot specify multiple output files", NULL);
                } else {
                    output_name = argv[i];
                }
            } else {
                throw(6, "Unrecognized option", NULL);
            }
        } else { // treat as a file name
            file_name = argv[i];
            if ((name_ext = strrchr(file_name, '.')) == NULL ||
                    (strcmp(name_ext, ".milk") && strcmp(name_ext, ".k"))) {
                throw(7, "File format not recognized", NULL);
            } else if (output_name == NULL) { // output file name not specified
                if ((output_name = calloc(strlen(file_name), sizeof(char))) == NULL) {
                    throw(3, "Insufficient memory", NULL);
                } else {
                    strncpy(output_name, file_name, name_ext - file_name);
                    open_file(file_name, output_name);
                    free(output_name);
                }
            } else { // output file name specified
                open_file(file_name, output_name);
            }
            dputs("File processed.");
            output_name = NULL;
            files_count++;
        }
    }

    if (files_count == 0) {
        throw(1, "No input files", NULL);
    }
    return 0;
}
