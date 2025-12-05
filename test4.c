// test4.c - if/else, while, use-before-init

int a, b;
int flag;

if (a > 0) {          // 'a' used before initialization
    b = 1;
} else {
    b = 2;
}

while (b < 10) {
    b = b + 1;
}

flag = 0;
if (b > 5 && flag == 0) {
    flag = 1;
}
