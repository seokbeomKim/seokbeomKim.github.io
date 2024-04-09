---
draft: true
title: "__is_constexpr macro in kernel"
date: 2021-03-21T22:44:03+09:00
toc: false
draft: false
categories:
- Kernel
tags:
- __is_constexpr
- c
---

커널에서 한 가지 재미있는(?) 매크로를 발견했다. 깊이 살펴보고 나니, GCC로 컴파일
시에 삼항 연산자를 이러한 방식으로 사용할 수 있다는 점에 한 번 놀랐고 이러한
방식으로 매크로를 활용할 수 있다는 것에 다시 한번 놀랐다. 가히 변태적인
매크로다. 관련 패치를 보고 리누즈가 한 말에 완전 동의한다.

	That is either genius, or a seriously diseased mind.

추가한 매크로는 ICE (Integer Constant Expression) 을 알아내기 위한 매크로이고
아래와 같이 정의한다.

``` c++
#define __is_constexpr(x)						\
	(sizeof(int) == sizeof(*(8 ? ((void *)((long)(x) * 0l)) : (int *)8)))
```

이러한 매크로는 VLA (Variable Length Arrays)를 제거하기 위한 패치의 일부인데,
GCC의 -Wvla 옵션으로는 아래와 같은 상황을 구분하지 못하고 경고를 출력한다.

``` c++
#define BTRFS_NAME_LEN 255
#define XATTR_NAME_MAX 255

char namebuf[max(BTRFS_NAME_LEN, XATTR_NAME_MAX)];
```

단순하게 배열의 크기를 선언하는 데에 있어서 프로그래머라면 당연하게 컴파일
타임에 정의되는 것이므로 VLA 가 아니라고 생각하겠지만, GCC는 이를 VLA 로
처리해버린다. 이를 해결하기 위해 만든 매크로가 위의 매크로이다. 기존의 max
매크로 대신, is_constexpr 매크로를 사용한 max_t 등을 새로 구현하여 VLA에 대한
에러를 성공적으로 제거했다.

그렇다면, 이 매크로는 어떻게 동작하는 걸까?

복잡해 보이지만, 알고보면 간단하다. ICE 인 경우 내부 값은 `((void *) NULL)` 이
된다. 이 때 리턴 값은 `(void *) NULL` 이 아니라, 삼항 연산자의 마지막 항 `(int
*)8`에 의해 자동으로 `(int *) NULL`이 되어 `sizeof(int) == sizeoof(*(int
*)NULL)` 을 만족하게 된다. 만약 ICE가 아닌 경우에는, 위 값은 `(void *)(possible
values)` 가 되고 결국 `sizeof(*(void *)value) == 1` 이 된다.

내부적으로 long으로 캐스팅하고 난 뒤에 0L으로 곱하는 이유는 아키텍처에 따라
64비트 변수에 대해 발생할 수 있는 컴파일러 에러를 없애기 위함이다.

# 참고 링크

- https://stackoverflow.com/questions/49481217/linux-kernels-is-constexpr-macro
- https://lkml.org/lkml/2018/3/20/845
