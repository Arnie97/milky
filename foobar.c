#include <stdio.h>

int main(int argc, char const *argv[])
{
    int foo, bar;
    scanf("%d %d", &foo, &bar);
    if (bar == 9) {
        while (foo < bar) {
            switch (foo) {
            case 1:
                printf("foo = 1\n");
                break;
            case 2:
                printf("foo = 2\n");
            case 0:
            case 4:
            case 6:
            case 8:
                printf("foo is even\n");
                break;
            default:
                printf("foo is unknown\n");
            }
            foo += bar;
        }
    } else if (foo == 9) {
        for (int i = 0; i < 10; ++i) {
            printf("%d ", i);
        }
    } else {
        do {
            foo -= bar;
        } while (foo > 0);
        printf("foo: %d, bar: %d\n", foo, bar);
    }
    return 0;
}