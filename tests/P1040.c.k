#include <stdio.h>
#include <string.h>
#include <ctype.h>
#define LENGTH 1500

int main(void):
    char input[LENGTH + 2], output[LENGTH + 1]
    *input = '+'
    scanf("%s", input + 1)
    memset(output, 0, LENGTH + 1)
    char *p_in = input + strlen(input), *p_out = output + LENGTH

    int sum = 0, plus_encountered = 0
    while --p_in >= input:  // calculate from right to left
        if *p_in == '+':
            *p_in = '0'  // allow the carries to be processed
            plus_encountered = 1
        elif isspace(*p_in):
            continue  // just ignore them
        elif !isdigit(*p_in):
            return 1  // unexpected character

        sum += *p_in - '0' + *p_out
        if sum >= 10:
            *p_out = sum - 10
            sum = 1  // the carry is no more than one
        else:
            *p_out = sum
            sum = 0
        p_out--

        if plus_encountered:
            if sum != 0:  // deal with ripple carries
                p_in++
                continue
            p_out = output + LENGTH  // reset the position
            plus_encountered = 0

    for p_out = output; p_out <= output + LENGTH; p_out++:
        if *p_out != 0:  // skip leading zeros
            break

    if p_out == output + LENGTH + 1:
        putchar('0')  // every bit is zero
    else:
        while p_out <= output + LENGTH:
            putchar('0' + *p_out++)  // only for test
    putchar('\n')
    return 0
