#ifndef COLOR_H_INCLUDED
#define COLOR_H_INCLUDED

#ifndef _WIN32

// ANSI RGB
#define RED     1
#define GREEN   2
#define BLUE    4

#else

// Windows RGB
#define RED     4
#define GREEN   2
#define BLUE    1

#endif

// CMYK & white
#define CYAN    (GREEN + BLUE)
#define MAGENTA (RED + BLUE)
#define YELLOW  (RED + GREEN)
#define BLACK   0
#define WHITE   (RED + GREEN + BLUE)

// Other attributes
#define RESET  -1
#define BRIGHT  8

#endif /* COLOR_H_INCLUDED */
