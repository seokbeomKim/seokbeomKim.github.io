---
title: "Do While"
date: 2020-04-01T23:55:32+09:00
categories:
- c
tags:
- do_while
toc: false
---

## 개요

커널 매크로에 `do { .. } while(0)` 구문을 사용하는 것을 보게 되었다. 사내 코드에서도 이러한 구문들이 많이 보였는데 처음에는 의미없이 이상하게 짜여진 코드라고 생각했다. 그런데 그런 구문에도 의미가 있었다. <https://kernelnewbies.org/FAQ/DoWhile0> 링크를 보면 이러한 구문을 만든 이유가 기술되어 있다. 이러한 구문에 대한 이유는 아래와 같다.

1. 빈 구문(empty statement)는 컴파일러가 경고를 낸다.
2. 지역 변수를 선언할 수 있는 구역을 만들어준다.
3. 조건문을 포함한 코드에서 복잡한 형태의 매크로를 사용할 수 있도록 해준다.

## 조건문을 포함한 코드에서의 매크로 사용

``` c++
#define FOO(x) \
    printf("arg is %s\n", x); \
    do_something_useful(x);
```

이 때 위처럼 정의한 매크로를 조건문과 함께 사용하게 된다면 아래와 같이 사용하게 된다.

``` c++
if (blah == 2) {
    FOO(blah);
}
```

그리고 이 구문에 매크로가 적용된 것을 살펴보면,
``` c++
if (blah == 2)
    printf("arg is %s\n", blah);
    do_something_useful(blah);;
```

위의 코드처럼 적용될 것이다. 이 때 문제가 되는 것은 `do_something_useful(blah);`가 조건에 관계없이 수행된다는 점이다. 이러한 매크로가 조건문에서 싱글라인 구문으로 사용된다면 문제가 될 수 있기에, do { ... } while(0) 을 사용하여 이러한 문제를 방지한다.

``` c++
if (blah == 2)
    do {
        printf("arg is %s\n", blah);
        do_something_useful(blah);
    } while(0);
```

아래와 같이 일반적인 블록 구문을 사용한다고 가정했을 때, 특정한 경우에 위 코드는 동작하지 않는다.

``` c++
#define exch(x,y) { int tmp; tmp=x; x=y; y=tmp; }
if (x > y)
    exch(x,y);
else
    do_something();
```

이 때, 매크로를 적용하면 아래와 같이 적용되어 버린다.

``` c++
if (x > y) {
    int tmp;
    tmp = x;
    x = y;
    y = tmp;
}
;   // 빈 구문
else
    do_something();
```

if문 블록 다음에 나오는 세미콜론으로 인해 "parse error before else" 문제가 발생하게 된다. 이 때 do {...} while(0) 구문을 이용하여 매크로를 정의하면 아래와 같이 관련 에러를 피할 수 있다.

``` c++
if (x > y)
    do {
        int tmp;
        tmp = x;
        x = y;
        y = tmp;
    } while(0);
else
    do_something();
```

## 대체 구문

`gcc`에서 이 do-while-0 구문을 대체할 수 있는 구문 표현을 추가했다. 아래와 같은 이러한 표현은 언급한 모든 이점을 갖는 동시에 가독성도 보장된다.

``` c++
#define FOO(arg) ({
    typeof(arg) lcl;
    lcl = bar(arg);
    lcl;
})
```
