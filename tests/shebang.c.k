#!/bin/sh
/*usr/bin/env milky $0 && gcc -Wall -std=c99 -o "${0/.c.k/}" "${0/.k/}" && "${0/.c.k/}" $@; ret=$?; rm -f "${0/.k/}" "${0/.c.k/}"; exit $ret; */

#include <stdio.h>

int main():
    puts("hello world")
