// test5.c - for loop, while, arrays, unused variable

int i, n;
int sum;
int arr[3];

n = 3;
sum = 0;

for (i = 0; i < n; i = i + 1) {
    sum = sum + i;
}

while (i < 10) {
    i = i + 1;
}

int unused;
