struct /* a */ primary /* test */:
    int *pointer
    int bit_width => 9
    struct primary *next
    enum nested:
        YES, NO

struct primary *self(struct primary *input):
    if 1:
        pass
    return input

int main(void):
    struct a, *b, **c
    c = &(b = self(&a))
