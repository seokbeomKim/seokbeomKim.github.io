---
draft: true
title: "C언어에서의 type-check"
date: 2020-04-10T00:13:53+09:00
toc: false
categories:
- c
tags:
- type check
---

## 개요

리눅스 커널을 살펴보다 보면 독특한 형태의 매크로 또는 타입 정의를 통해 타입
체크를 하는 것을 알 수 있다. 이 페이지에서는 앞으로 커널 분석 중에 자주 보게될
타입 체크에 대해 정리하고 내용이 추가될 때마다 페이지를 업데이트 하도록 한다.


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

## primitive type

커널 내의 `minmax.h` 파일을 살펴보면 아래와 같이 정의된 매크로가 있다. 단순하게
인자로 전달된 변수들의 타입 포인터로 캐스팅한 후 각각의 포인터 변수 크기를
비교한다. 이는 런타임에 인자로 전달된 x, y를 비교하기 위함이 아니라 컴파일
타임에 에러를 발생시키기 위한 용도이며 `!!` 를 통해서 두 개 변수의 크기를
비교하여 안전하게 `boolean` 형태로 변환하는 것도 확인할 수 있다.

``` c++
#define __typecheck(x, y) \
	(!!(sizeof((typeof(x) *)1 == (typeof(y) *)1)))
```
