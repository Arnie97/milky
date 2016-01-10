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

static inline size_t
file_size(FILE *fp) {
    fseek(fp, 0, SEEK_END);
    size_t size = ftell(fp);
    rewind(fp);
    return size;
}

static void
load_file(FILE *fp)
{
    line_pos = 1;

    size_t size = file_size(fp);
    line = malloc(2 + size + 1 + 3);
    if (!line) {
        throw(3, "Insufficient memory", NULL);
    }
    line[0] = line[1] = '\n';
    fread(&line[2], size, 1, fp);
    if (line[++size] != '\n') {
        line[++size] = '\n';
    }
    for (int i = 0; i < 3; i++) {
        line[++size] = '\0';
    }
}

static void
open_file(const char *input_name, const char *output_name)
{
    dprintf(("%s >> %s\n", input_name, output_name));
    FILE *fp_in = fopen(input_name, "r");
    if (!fp_in) {
        goto handler;
    } else {
        load_file(fp_in);
        fclose(fp_in);
    }

    FILE *fp_out = fopen(output_name, "w");
    if (!fp_out) {
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
        } else if (argv[i][0] == '-') { // treat argument as an option
            if (strcmp(argv[i], "-o") == 0) {
                if (++i >= argc) {
                    throw(4, "Missing filename after '-o'", NULL);
                } else if (output_name) {
                    throw(5, "Cannot specify multiple output files", NULL);
                } else {
                    output_name = argv[i];
                }
            } else {
                throw(6, "Unrecognized option", NULL);
            }
        } else { // treat argument as a file name
            file_name = argv[i];
            name_ext = strrchr(file_name, '.');
            if (
                !name_ext ||
                (strcmp(name_ext, ".milk") && strcmp(name_ext, ".k"))
            ) {
                throw(7, "File format not recognized", NULL);
            } else if (!output_name) { // output file name not specified
                output_name = calloc(strlen(file_name), sizeof(char));
                if (!output_name) {
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
    } else {
        return 0;
    }
}
