---
title: "컴파일 타임에 매크로 변수 값 확인하기"
date: 2021-10-16T02:19:05+09:00
toc: false
draft: false
tags:
- preprocessor
---

# 개요

현업에서 사용하는 코드 중 상당히 많은 부분들이 매크로 변수 형태로 정의되어
사용되고 있다. 이러한 변수들은 런타임 때 정의되지 않기 때문에 굳이 값을 확인하기
위해서 불필요하게 런타임에서까지 확인해볼 필요는 없지만, 통상적으로 이러한
변수들의 값이 어떻게 설정되어 있는지에 대한 로깅 코드들이 많이 있다.

그렇다면, 컴파일 타임에서 매크로 변수의 값을 알 수 있는 방법은 없을까? #pragma
와 같은 전처리 키워드를 사용하면 가능하다. 예를 들어, 아래의 코드를 보자.

<!--more-->

``` cpp
#include <stdio.h>

/* #define VAR_NAME_VALUE(var) #var "="  VALUE(var) */
#define DO_PRAGMA(x) _Pragma (#x)

/* Some test definition here */
#define DEFINED_BUT_NO_VALUE
#define DEFINED_INT 3
#define DEFINED_STR "ABC"

/* definition to expand macro then apply to pragma message */
#define VALUE_TO_STRING(x) #x
#define VALUE(x) VALUE_TO_STRING(x)
#define VAR_NAME_VALUE(var) #var "="  VALUE_TO_STRING(var)

/* Some example here */
#pragma message(VAR_NAME_VALUE(NOT_DEFINED))
#pragma message(VAR_NAME_VALUE(DEFINED_BUT_NO_VALUE))
#pragma message(VAR_NAME_VALUE(DEFINED_INT))
#pragma message(VAR_NAME_VALUE(DEFINED_STR))

#define PRINT_INT(x) DO_PRAGMA(message(VAR_NAME_VALUE(DEFINED_INT)))

PRINT_INT(DEFINED_INT);

#if DEFINED_INT > 2
#warning "ERROR"
#endif

int main(void)
{
	printf("This is sample application to make compiler to \
	       show the value of macro variable\n");

	return 0;
}
```

위와 같이 매크로를 정의하면, 컴파일 시에 `PRINT_INT` 매크로 뿐만 아니라 `#pragma
message(...)` 를 이용하여 각각의 매크로 변수들의 값을 직접 출력할 수 있다.

이제 커널의 fixmap 영역이 정의된 부분에서 확인해보자. (사실 fixmap 영역에서
사용하는 값들을 직접 확인해보기 위함이었는데 enum 으로 정의되어 있는 부분은
제대로 출력되지 않았다.)

``` cpp
...
};

#pragma message(VAR_NAME_VALUE(FIX_FDT_SIZE))

./arch/arm64/include/asm/fixmap.h:102:9: note: #pragma message: FIX_FDT_SIZE=(0x00200000 + 0x00200000)
  102 | #pragma message(VAR_NAME_VALUE(FIX_FDT_SIZE))
      |         ^~~~~~~
```
