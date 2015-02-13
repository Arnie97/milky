#include "milky.h"
#include "translator.h"
#include "main.h"

char line[LINE_BUF_SIZE] = "~";
int line_pos = 1;

int
main(int argc, char **argv)
{
    FILE *fp = fopen("foobar.milk", "r");
    if (fp == NULL) {
        fprintf(stderr, "Test file not found!\n");
        return 1;
    }
    char buffer[LINE_BUF_SIZE];
    while (fgets(buffer, LINE_BUF_SIZE, fp) != NULL) {
        strcat(line, buffer);
    }
    fclose(fp);
    parse_file();
    return 0;
}
