#include <stdio.h>

char chr1 = '\''
char chr2 = '\\'
char str1a[] = "\""
char str1b[] = "#\""
char str2a[] = "\\"
char str2b[] = "#\\"
char str3a[] = "\\\""
char str3b[] = "#\\\""
char str4a[] = "\\\\"
char str4b[] = "#\\\\"

char str_multiline[] = "
    with EOL -> .
    without eol -> .\
    fake escape -> .\\
    escaped as is -> .\n\
"

int main(void):
    puts(str_multiline)
    return 0
