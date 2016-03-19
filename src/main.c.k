#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "input.h"
#include "token.h"
#include "error.h"
#include "translator.h"

int line_pos
char *line = NULL, *file_name = "milky"
FILE *output


static inline size_t file_size(FILE *fp):
    "Return length of the specified file in bytes,
        and rewind it to the beginning."
    fseek(fp, 0, SEEK_END)
    size_t size = ftell(fp)
    rewind(fp)
    return size


static size_t shebang_size(FILE *fp, size_t file_size):
    "If the file begins with shebang,
        return the size of its first line. Otherwise, return zero."
    size_t shebang
    if getc(fp) == '#' && getc(fp) == '!':
        shebang = 2
        while getc(fp) != '\n' && shebang < file_size:
            shebang++
    else:
        shebang = 0
    return shebang


static void load_file(FILE *fp):
    "Load the specified file into heap memory,
        but skip the shebang line, if it exists."
    line_pos = 1

    size_t size = file_size(fp)
    size_t shebang = shebang_size(fp, size)
    dprintf((WHITE, "file length %u, including shebang %u\n", size, shebang))
    size -= shebang

    line = malloc(2 + size + 1 + 3)
    if !line:
        throw(3, "Insufficient memory", NULL)

    line[0] = line[1] = '\n'
    fseek(fp, shebang, SEEK_SET)
    fread(&line[2], size, 1, fp)
    if line[++size] != '\n':
        line[++size] = '\n'
    for int i = 0; i < 3; i++:
        line[++size] = '\0'


static int open_file(const char *input_name, const char *output_name):
    "Create input and output handles by file names."
    dprintf((BRIGHT + YELLOW, "%s >> %s: ", input_name, output_name))
    FILE *fp_in = fopen(input_name, "r")
    if !fp_in:
        goto handler
    else:
        load_file(fp_in)
        fclose(fp_in)

    FILE *fp_out = fopen(output_name, "w")
    if !fp_out:
        goto handler

    else:
#ifdef _DEBUG
        output = stdout
#else
        output = fp_out
#endif
        int i = parse_file()
        fclose(fp_out)
        return i

    handler => throw(2, "Unable to open specified file", NULL)


int main(int argc, char *argv[]):
    "Parse command line options."
    int files_count = 0, first_err = 0
    char is_option = 1, *output_name = NULL, *name_ext

    for int i = 0; i < argc; i++:
        if is_option && strcmp(argv[i], "--"): // separator before file names
            is_option = 0

        elif argv[i][0] == '-': // treat argument as an option
            if strcmp(argv[i], "-o") == 0:
                if ++i >= argc:
                    throw(4, "Missing filename after '-o'", NULL)
                elif output_name:
                    throw(5, "Cannot specify multiple output files", NULL)
                else:
                    output_name = argv[i]
            else:
                throw(6, "Unrecognized option", NULL)

        else: // treat argument as a file name
            file_name = argv[i]
            name_ext = strrchr(file_name, '.')
            if (
                !name_ext ||
                (strcmp(name_ext, ".milk") && strcmp(name_ext, ".k"))
            ):
                throw(7, "File format not recognized", NULL)

            elif !output_name: // output file name not specified
                size_t output_name_length = name_ext - file_name
                output_name = malloc(output_name_length + 1)
                if !output_name:
                    throw(3, "Insufficient memory", NULL)
                else:
                    strncpy(output_name, file_name, output_name_length)
                    output_name[output_name_length] = '\0'
                    first_err = first_err || open_file(file_name, output_name)
                    free(output_name)

            else: // output file name specified
                first_err = first_err || open_file(file_name, output_name)

            dprintf((BRIGHT + YELLOW, "File processed.\n"))
            output_name = NULL
            files_count++

    if files_count == 0:
        throw(1, "No input files", NULL)
    else:
        return first_err
