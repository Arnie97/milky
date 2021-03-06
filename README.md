## Milky - the Indent-based Language liKe pYthon
<img src="milky.png" alt="Logo of Milky" width="200">

[![Build Status](https://travis-ci.org/Arnie97/milky.svg)](https://travis-ci.org/Arnie97/milky)
[![Coverage Status](https://codecov.io/github/Arnie97/milky/coverage.svg?branch=master)](https://codecov.io/github/Arnie97/milky?branch=master)


### Introduction
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

For more examples on syntax details, don't forget the [source code](src) of milky compiler - it's also written in milky!


### Build
As mentioned, the milky compiler is fully written in milky language itself.
Hence we'll need C toolchain and a copy of compiled milky compiler (version `0.13.6+`) to bootstrap the latest milky.

To build from scratch, you may build a milky compiler from the 'bootstrap' branch:

```bash
$ git clone https://github.com/Arnie97/milky
$ cd milky
$ git checkout bootstrap
$ make
$ sudo make install
```

Or, simply execute `sudo make bootstrap` to build from Github archive.

Then we can get back to the latest milky source:

```bash
$ git checkout master
$ make
$ sudo make install
```


### Naming Conventions
Assume that you've already installed milky in your `$PATH`:

```c
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


### Output Style
Milky outputs are designed to be as similar to the corresponding inputs as possible.
Match on the line level is strictly guaranteed, which is useful when working with other tools, such as GDB or Gcov.

Taking [hello.c.k above](#naming-conventions) and Gcov as an example:

```bash
$ milky hello.c.k
$ gcc --coverage -o hello hello.c   # generates hello.gcno
$ ./hello                           # generates hello.gcna
$ cp hello.c.k hello.c              # uses milky source instead in Gcov
$ gcov hello                        # creates coverage report
```

If you prefer a cleaner programming style in your outputs, simply apply a code formatter.
[Astyle](http://astyle.sourceforge.net) or [Uncrustify](http://uncrustify.sourceforge.net) might be handy.


### C++ Support
Milky was initially designed for the C language.
As C++ is almost a super set of C, and shares its basic syntaxes, milky should work with most C++ source codes, although not guaranteed.

Currently, the milky compiler is not deliberately designed to support C++ specific features, excepted for support of scope resolution operators (i.e. `::`) since version `0.8.9`.

In the future, milky might be developed to provide better C++ support.


### License
GPL.


### Thanks
The initial versions of milky compiler was based on [sample codes](http://kmaebashi.com/programmer/devlang/book/download.html) from the book [「プログラミング言語を作る」](http://kmaebashi.com/programmer/devlang/book).
