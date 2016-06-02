#include "token.h"
#include "base64.h"
#include "error.h"

static int pos_in_token
static char *token_str

static void base64_split(const char *str)
static inline void base64_encode(const unsigned char *chunks, int len)


int base64_magic(Token *token, int len):
    "Transform a non-ascii string into a valid ascii identifier."
    Token temp = *token
    pos_in_token = 0
    token_str = token->str
    token_str[pos_in_token++] = '_'
    token_str[pos_in_token++] = '_'

    int size = pos_in_token + (len / 3 * 4 + len % 3 + 2) * 2 + 1
    if size >= MAX_TOKEN_SIZE:
        throw(13, "Non-ascii token too long", token)

    base64_split(temp.str)
    return pos_in_token


static void base64_split(const char *str):
    "Split given binary string into groups of three."
    unsigned char chunks[3]
    unsigned i = 0
    while *str:
        chunks[i++] = *str++
        if i == 3:
            base64_encode(chunks, 3)
            i = 0

    if i: // deal with the remainder
        for int j = i; j < 3; j++:
            chunks[j] = '\0'
        base64_encode(chunks, i)


static inline void base64_encode(const unsigned char *chunks, int len):
    "Convert three bytes into four base64 characters."

    // there're only 63 valid characters [A-Za-z0-9_],
    // hence we have to use escape sequences to avoid conflicts.
    static const char base64_alphabet[] = \
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789\0\1"

    // reshape an 3 * 8 array into an 4 * 6 array
    int encoded[4] = {
        chunks[0] >> 2,
        (chunks[0] & 0x03) << 4 | chunks[1] >> 4,
        (chunks[1] & 0x0f) << 2 | chunks[2] >> 6,
        chunks[2] & 0x3f
    }

    // translate characters with the alphabet
    for int i = 0; i <= len; i++:
        char c = base64_alphabet[encoded[i]]

        // 0x3e maps onto escape sequence "_0", and 0x3f "_1"
        if c < '0':
            token_str[pos_in_token++] = '_'
            token_str[pos_in_token++] = '0' + c
        else:
            token_str[pos_in_token++] = c
