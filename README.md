### Milky - the Indent-based Language liKe pYthon
<img src="milky.png" alt="Logo of Milky" width="200">


#### Introduction
Milky is a toy language that compiles into C, just like CoffeeScript compiles into JavaScript.
As its name suggests, the syntax of milky is heavily based on indentations, and is very similar to Python.
It is also inspired by Ruby, Go, Swift and many other programming languages.

Let's have a look at some examples. The following is a milky version of the famous [FizzBuzz Test](http://c2.com/cgi/wiki?FizzBuzzTest):
```c
#include <stdio.h>
#include <stdbool.h>

int main(void):
    for int i = 1; i <= 100; i++:
        bool fizz = (i % 3 == 0)
        bool buzz = (i % 5 == 0)

        if fizz:
            fputs("Fizz", stdout)
        if buzz:
            fputs("Buzz", stdout)
        if fizz || buzz:
            putc('\n', stdout)
        else:
            printf("%d\n", i)
```

If you are new to milky, you can begin with a piece of C source code - basically, add proper indentations and colons, then remove redundant parentheses, braces and semicolons, and now you've got some code in milky.

For more examples on syntax details, you can check the source code of milky compiler - it's also written in milky!


#### Build
As mentioned, the milky compiler is fully written in milky language itself.
Hence you'll need a copy of compiled milky compiler (version `0.13.6+`) to bootstrap the latest milky.


#### Getting started
Assume that you've already installed milky to somewhere in your `$PATH`:
```bash
$ cat > hello.c.k << EOF
#include <stdio.h>
int main(int argc, char *argv[]):
    puts("Hello, World!")
EOF

$ milky hello.c.k           # prints "hello.c.k: Well done."
$ c99 -o hello hello.c
$ ./hello                   # prints "Hello, World!"
```

As shown above, milky source codes should be named with suffix `.k` (or `.milk`), i.e. `foo.c.k` for a C source file and `bar.h.k` for a C header file. Unless explicitly given, the output file will be named after the corresponding input, but without the `.k` suffix. You can specify the output file name with option `-o`:

```bash
$ milky in1.c.k -o out2.c in2.c.k -o out3.c in3.c.k
```

In this example, the milky compiler will compile `in1.c.k` into `in1.c`, `in2.c.k` into `out2.c.k` and `in3.c.k` into `out3.c.k`.
As you can see, multiple inputs can be specified at the same time, hence the desired output name must be given just before the corresponding input file to prevent ambiguity.


#### C++ Support
Milky was initially designed for the C language.
As C++ is almost a super set of C, and shares its basic syntaxes, milky should work with most C++ source codes, although not guaranteed.

Currently, the milky compiler is not deliberately designed to support C++ specific features, excepted for support of scope resolution operators (i.e. `::`) since version `0.8.9`.

In the future, milky might be developed to provide better C++ support.


#### License
GPL.


#### Thanks
The initial versions of milky compiler was based on [sample codes](http://kmaebashi.com/programmer/devlang/book/download.html) from the book [「プログラミング言語を作る」](http://kmaebashi.com/programmer/devlang/book).
