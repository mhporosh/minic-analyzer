// test1.c - clean program, no errors or warnings

int a, b;
float x;
char c[5];

a = 5;
b = a + 3;
x = a + b * 2;

c[0] = 1;
c[1] = c[0] + a;

// simple if
if (a < 10) {
    b = b + 1;
}

// simple while
while (b < 20) {
    b = b + 2;
}
