---
title: "C ARRAY_SIZE 매크로와 포인터 기초"
date: 2020-03-28T00:54:01+09:00
categories:
- c
tags:
- ARRAY_SIZE
toc: false
---

## 개요

칩 검증 코드를 수정하기 위해 간단한 루틴을 작성하고 있던 도중 커널에서 제공하는 ARRAY_SIZE 매크로가 의도한대로 동작하지 않아 살펴보기 시작했다. 그러던 도중 <https://kldp.org/node/34268>과 같은 원인이라는 것을 알게되고 C 기초를 또 다시 한번 공부하게 되었다.

커널에서 사용하는 `ARRAY_SIZE`는 아래와 같이 구현되어 있다.

``` c++
#define ARRAY_SIZE(x) (sizeof(x)/sizeof(x[0]))

// examples
for (idx = 0; idx < ARRAY_SIZE(pArr); idx++) {
    // do something
})
```

본래 의도한대로라면, 배열의 크기만큼 for 구문을 반복해서 수행해야 하지만, pArr 자체가 함수의 인자로써 전달된 것이라면 얘기가 달라진다. 함수의 인자, 즉 포인터의 사이즈를 받게 되므로 `ARRAY_SIZE(x)`는 포인터 변수 자체의 크기를 첫 번째 요소의 크기로 나눈 것이 된다. 설명보다 직접 코드를 통해 증명해보자.

## 예제

``` c++
#include <stdio.h>
#include <stdlib.h>

#define ARRAY_SIZE(x) (sizeof(x)/sizeof(x[0]))

void tc1(void) {
    int arr[] = {1, 2, 3};
    printf("ARRAY_SIZE = %ld\n", ARRAY_SIZE(arr));
}

void tc2(int *pArr) {
    printf("ARRAY_SIZE = %ld\n", ARRAY_SIZE(pArr));
    printf("sizeof(x) = %d, sizeof(x[0]) = %d\n", sizeof(pArr), sizeof(pArr[0]));
}

void tc3(char *pArr) {
    printf("ARRAY_SIZE = %ld\n", ARRAY_SIZE(pArr));
    printf("sizeof(x) = %d, sizeof(x[0]) = %d\n", sizeof(pArr), sizeof(pArr[0]));
}

void tc4(unsigned long *pArr) {
    printf("ARRAY_SIZE = %ld\n", ARRAY_SIZE(pArr));
    printf("sizeof(x) = %d, sizeof(x[0]) = %d\n", sizeof(pArr), sizeof(pArr[0]));
}

int main(void) {
    int arrInt[] = {4, 5, 6, 7};

    printf("size of int = %d, size of long = %d\n", sizeof(int), sizeof(long));
    printf("size of pointer value = %d\n", sizeof(arrInt[0]));

    printf("[Test case 1]\n");
    tc1();

    printf("[Test case 2]\n");
    tc2(arrInt);

    printf("[Test case 3]\n");
    tc3(arrInt);

    printf("[Test case 4]\n");
    tc4(arrInt);
}
```

위 코드를 실행하면 아래와 같은 결과를 얻는다.

``` text
size of int = 4, size of long = 8
size of pointer value = 4
[Test case 1]
ARRAY_SIZE = 3
[Test case 2]
ARRAY_SIZE = 2
sizeof(x) = 8, sizeof(x[0]) = 4
[Test case 3]
ARRAY_SIZE = 8
sizeof(x) = 8, sizeof(x[0]) = 1
[Test case 4]
ARRAY_SIZE = 1
sizeof(x) = 8, sizeof(x[0]) = 8
```

함수의 파라미터로 정의되어 있는 포인터 변수들은 프로세서 아키텍처의 주소 크기만큼을 갖는다. 테스트는 64비트에서 이루어졌으므로 첫 번째 테스트케이스를 제외한 나머지에서 `sizeof(x)`는 모두 8(64비트)를 갖는다. 그리고 포인터의 타입에 따라 첫 번째 인자가 갖는 크기는 달라지게 되므로 결과값은 모두 달라지게 된다. 때문에 `ARRAY_SIZE` 매크로는 함수 내에 지역 변수로서 정의한 경우에는 사용할 수 있지만 함수로 넘겨서 사용하는 경우에는 사용이 불가능하다. 배열의 크기를 반드시 명시적으로 전달해줘야 전달받은 루틴에서 정상적으로 그 크기를 다룰 수 있다.

기초적인 내용인데도 불구하고 막상 문제에 닥치니 제대로 알기가 어렵다. 아직 한참 멀었다.
