# Strategy for solving Day 24
[thanks u/etotheipi1!](https://www.reddit.com/r/adventofcode/comments/rnejv5/2021_day_24_solutions/hps5hgw/)

Each digit's instructions decompile to the following Python:
```
w = int(input())
x = int((z % 26) + b != w)
z //= a
z *= 25*x+1
z += (w+c)*x
```

Variable `a` is either 1 or 26, which represents "push"ing or "pop"ing a digit in base 26 to and from `z`.
E.g. if `a` is set to 1, then the above algorithm can be simplified to
```
w = int(input())
z *= 26
z += w+c
```

So in order for us to end the program with `z == 0`, we need every pop instruction to remove the base 26 digit
via `z //= 26`, w/o adding anything back. Therefore, we need `x == 0` for all pop operations and need to satisfy the following expression:
```
(z % 26) + b == w
=> (w_lp + c_lp) + b_curr == w_curr
=> w_lp + c_lp == w_curr - b_curr
```
where the `lp` suffix refers to `last pushed`. 

This means pairs of digits in the 14 digit number are linked by such a constraint. Given our decompiled instructions:
```
Digit   A   B   C
1       1   12  1
2       1   13  9
3       1   12  11
4       26  -13 6
5       1   11  6
6       1   15  13
7       26  -14 13
8       1   12  5
9       26  -8  7
10      1   14  2
11      26  -9  10
12      26  -11 14
13      26  -6  7
14      26  -5  1
```

we can match each push digit to its pop and come up with a set of constraints:
```
I[3] + 11 == I[4] + 13
I[6] + 13 == I[7] + 14
I[8] + 5 == I[9] + 8
I[10] + 2 == I[11] + 9
I[5] + 6 == I[12] + 11
I[2] + 9 == I[13] + 6
I[1] + 1 == I[14] + 5
```
which can be further simplified as:
```
I[3] == I[4] + 2
I[6] == I[7] + 1
I[8] == I[9] + 3
I[10] == I[11] + 7
I[5] == I[12] + 5
I[2] == I[13] - 3
I[1] == I[14] + 4
```
note that 0 is not a valid digit.

NOW we just need to find the maximum and minimum base 10 digits that satisfy each of these equations, and we've found our solutions!
```
            1   2   3   4   5   6   7   8   9   10  11  12  13  14
max digits  9   6   9   7   9   9   8   9   6   9   2   4   9   5
min digits  5   1   3   1   6   2   1   4   1   8   1   1   4   1

max candidate num: 96979989692495
min candidate num: 51316214181141
```
