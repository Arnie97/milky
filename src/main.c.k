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


static inline long file_size(FILE *fp):
    "Return length of the specified file in bytes,
        and rewind it to the beginning."
    fseek(fp, 0, SEEK_END)
    long size = ftell(fp)
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
    long size = file_size(fp)

    // stream is not a file, so we can only read it by chunk
    if size == -1:
        size = 0
        size_t bytes_read
        repeat bytes_read == BUFFER_SIZE:
            line = realloc(line, 2 + size + BUFFER_SIZE + 1 + 3)
            if !line:
                throw(3, "Insufficient memory", NULL)
            bytes_read = fread(&line[2 + size], BUFFER_SIZE, 1, fp)
            size += BUFFER_SIZE
        size += bytes_read - BUFFER_SIZE

    // stream is a file, so we can get its size and read it as a whole
    else:
        size_t shebang = shebang_size(fp, size)
        dprintf((WHITE, "file length %u, including shebang %u\n", size, shebang))
        size -= shebang

        line = malloc(2 + size + 1 + 3)
        if !line:
            throw(3, "Insufficient memory", NULL)
        fseek(fp, shebang, SEEK_SET)
        fread(&line[2], size, 1, fp)

    line[0] = line[1] = '\n'
    if line[++size] != '\n':
        line[++size] = '\n'
    for int i = 0; i < 3; i++:
        line[++size] = '\0'


static int open_file(const char *input_name, const char *output_name):
    "Create input and output handles by file names."
    int parsing_error
    FILE *fp_in, *fp_out

#ifdef _DEBUG
    dprintf((
        BRIGHT + YELLOW, "%s >> %s: ",
        input_name?  input_name:  "<stdin>",
        output_name? output_name: "<stdout>"
    ))
    output_name = NULL
#endif

    if !input_name:
        load_file(stdin)
    elif (fp_in = fopen(input_name, "r")):
        load_file(fp_in)
        fclose(fp_in)
    else:
        goto handler

    if !output_name:
        output = stdout
        parsing_error = parse_file()
    elif (fp_out = fopen(output_name, "w")):
        output = fp_out
        parsing_error = parse_file()
        fclose(fp_out)
    else:
        goto handler

    return parsing_error

    handler => throw(2, "Unable to open specified file", NULL)


int main(int argc, char *argv[]):
    "Parse command line options."
    int files_count = 0, first_err = 0
    char is_option = 1, force_process = 0, *output_name = NULL, *name_ext

    for int i = 1; i < argc; i++:
        // treat argument as an option
        if is_option && argv[i][0] == '-' && argv[i][1] != '\0':

            // it could be a separator between options and file names
            if !strcmp(argv[i], "--"):
                is_option = 0

            // or, forcing a file with suffixes other than '.k' to be processed
            elif !strcmp(argv[i], "-f") || !strcmp(argv[i], "--force"):
                force_process = 1

            // or, specifying output path for the next given input
            elif !strcmp(argv[i], "-o") || !strcmp(argv[i], "--output"):
                if ++i >= argc:
                    throw(4, "Missing filename after '-o'", NULL)
                elif output_name:
                    throw(5, "Cannot specify multiple outputs for an input", NULL)
                else:
                    output_name = argv[i]

            else:
                throw(6, "Unrecognized option", NULL)

        // otherwise, treat argument as an input
            continue

        // specifying stdin as input
        if argv[i][0] == '-' && argv[i][1] == '\0':
            file_name = NULL

        else:
            file_name = argv[i]
            name_ext = strrchr(file_name, '.')
            if (
                !name_ext ||
                (strcmp(name_ext, ".milk") && strcmp(name_ext, ".k"))
            ):
                if !force_process:
                    throw(7, "File format not recognized", NULL)
                elif !output_name:
                    throw(8, "Output path must be explicitly specified", NULL)

        // output file name isn't specified, but input is
        // thus generate an output file name by removing the '.k' suffix
        if file_name && !output_name:
            size_t output_name_length = name_ext - file_name
            output_name = malloc(output_name_length + 1)
            if !output_name:
                throw(3, "Insufficient memory", NULL)
            strncpy(output_name, file_name, output_name_length)
            output_name[output_name_length] = '\0'
            first_err = first_err || open_file(file_name, output_name)
            free(output_name)

        // in other cases, it's unnecessary or unable to deduce an output name
        else:
            // stdout specified as output
            if output_name && output_name[0] == '-' && output_name[1] == '\0':
                output_name = NULL
            first_err = first_err || open_file(file_name, output_name)

        dprintf((BRIGHT + YELLOW, "File processed.\n"))
        force_process = 0
        output_name = NULL
        files_count++

    if files_count == 0:
        throw(1, "No input files", NULL)
    else:
        return first_err
