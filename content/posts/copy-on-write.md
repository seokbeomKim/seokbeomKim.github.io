---
title: "Copy on Write (CoW or COW)"
date: 2019-05-16T18:24:16+09:00
categories:
- Computer Science
tags:
- COW
- shadowing
- implicit sharing
keywords:
- tech
---

Copy-on-write은 리눅스 커널의 `fork()` 함수에서 사용하는 기법이다.

전통적인 `fork()`는 부모 프로세스의 모든 자원을 복사해 자식
프로세스에게 넘겨준다. 하지만 이러한 방식은 공유가 가능한 많은
데이터를 복사하므로 단순하고 비효율적이다. 게다가 새로 만든 프로세스가
곧바로 다른 프로그램을 실행한다면 복사 작업이 모두 헛수고가 되고 만다.

이러한 문제를 해결하기 위해 리눅스에서는 `Copy-on-write, COW` 기법을
이용하는데 기록사항 발생 시에 복사하는 기능으로 즉각적인 데이터의
복사를 지연하거나 방지하는 기법이다. 때문에 `fork()`를 사용하게 되면
프로세스의 주소 공간을 모두 복사하는 대신, 부모와 자식 프로세스가 같은
공간을 공유하고 있다가 기록 사항이 발생했을 때 사본을 만든다. (그
전까지는 읽기전용 상태로서 복사를 지연한다.)

`Copy-on-write`는 때때로 `implicit sharing`, `shadowing`이라고도
불리며 컴퓨터 프로그래밍에서 자원 관리 기법 중 하나로서 사용되는
기법이다. `write`라는 연산이 발생할 가능성이 있는 상태에서는 `write`가
전혀 발생하지 않을 가능성도 있는 법이다. 이러한 경우 `Copy-on-write`
기법은 자원 관리 측면에서 좋은 최적화 기법이 될 수 있다.

# 예제

아래는 위키 페이지에 나와있는 간단한 예제이다. 변수를 위한 메모리
할당에 있어서 아래 상황에서 `COW`를 사용할 수 있다.

``` c++
std::string x("Hello");
std::string y = x;      // x and y use the same buffer
y += ", World!";        // now y uses a different buffer, x still uses the same old buffer
```

# 출처
* https://en.wikipedia.org/wiki/Copy-on-write
* Chapter 3. Process in "Linux Kernel Development 3rd Edition"
