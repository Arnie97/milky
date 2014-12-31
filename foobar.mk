#include <stdio.h>

int main(int argc, char const *argv[]):
    int foo, bar
    scanf("%d %d", &foo, &bar)
    if bar == 9:
        while foo < bar:
            switch foo:
            case 1:
                printf("foo = 1\n")
            case 2:
                printf("foo = 2\n")
                fallthrough
            case 0, 4, 6, 8:
                printf("foo is even\n")
            default:
                printf("foo is unknown\n")
            foo += bar
    elseif foo == 9:
        for int i = 0;i < 10;++i:
            printf("%d ", i)
    else:
        until foo > 0:
            foo -= bar
        printf("foo: %d, bar: %d\n", foo, bar)
    return 0
