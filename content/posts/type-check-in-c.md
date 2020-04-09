---
title: "C언어에서의 type-check"
date: 2020-04-10T00:13:53+09:00
toc: false
categories:
- c
tags:
- type check
---

## 페이지 테이블에서의 타입 체크

ARM64 커널 소스에 있는 MMU 코드를 살펴보니 아래와 같이 특이하게
작성되어 있는 부분을 찾을 수 있었다.

``` c++
typedef u64 pteval_t;
typedef u64 pmdval_t;
typedef u64 pudval_t;
typedef u64 pgdval_t;

...

/*
 * These are used to make use of C type-checking..
 */
typedef struct { pteval_t pte; } pte_t;
#define pte_val(x)	((x).pte)
#define __pte(x)	((pte_t) { (x) } )

...

typedef struct { pgdval_t pgd; } pgd_t;
#define pgd_val(x)	((x).pgd)
#define __pgd(x)	((pgd_t) { (x) } )
```

왜 `enum`을 사용하지 않고 struct에 멤버변수를 이용해서 사용하는 걸까?
하는 의문에 간단히 답을 찾을 수 있었다. `enum`의 경우 정수형 값과
호환되기에 컴파일러의 type check 루틴에 강제할 수 없다. 컴파일
타임에서 타입 체크를 하도록 강제할 수 있지만 syntax 상으로 강제하기
위해서 위와 같이 한 개의 멤버를 가지는 구조체 타입을 이용하고 매크로를
정의하여 안전하게 타입 체크를 강제할 수 있도록 구현하는 것을 볼 수
있다.
