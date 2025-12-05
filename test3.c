// test3.c - redeclaration & unused

int a, b;
float a;        // redeclaration of 'a'
char c[5];
char c;         // redeclaration of 'c'

int usedVar;
usedVar = 10;
