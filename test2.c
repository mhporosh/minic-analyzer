// test2.c - undeclared, use-before-init, array misuse

int a;
int arr[10];

a = 5;
b = a + 1;          // 'b' undeclared

arr[2] = a;

int c;
d = c + 1;          // 'c' declared but not initialized, 'd' undeclared

arr2[0] = 1;        // 'arr2' undeclared
a[0] = 3;           // 'a' used with index but not declared as array
