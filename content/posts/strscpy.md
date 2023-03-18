---
title: "strcpy"
date: 2022-10-09T14:00:05+09:00
categories:
- Kernel
tags:
- strcpy
- strlcpy
- strscpy
---

## 개요
한달 전 회사에서 리눅스 디바이스 드라이버 코드에 MISRA-C, CERT-C 룰셋들을
이용하여 정적분석을 하는 도중, `strcpy` 에 대한 warning 을 어떻게 처리할까
고민하다가 LWN 에서 [Ushering out strlcpy()](https://lwn.net/Articles/905777/)
라는 기사문을 읽게 되었다. string copy에 대한 글을 읽고 블로그에 정리하자고
했는데 이제서야 겨우 정리할 수 있게 되었다.

리눅스 커널에서 문자열 복사를 위해 만들어진 매크로들은 다양하다. 몇 개의
시리즈(?)가 있는데 정리해보면 다음과 같다.

1. strcpy
2. strncpy
3. strlcpy
4. strscpy

## strcpy

`strcpy`를 나타내면 아래와 같이 간단하다.

```c
strcpy(s, t)
    char *s, *t;
    {
        while (*s++ = *t++)
	    ;
    }
}
```

하지만 이 경우 발생가능한 문제는 `destination` 크기가 `source`보다 작을 경우
`overrun`이 발생한다는 점이다. 이를 개선하고자 만들어진 것이 `strncpy` 이다.

## strncpy

`strncpy`는 아래와 같은 프로토타입을 갖는다.

```c
char *strncpy(char *dest, char *src, size_t n);
```

명시적으로 복사하고자 하는 크기를 인자로 넘겨주기 때문에 앞서 `strcpy`처럼
`overrun`이 발생할 일이 거의 없다. 하지만 이처럼 문제가 없어보이는 데에도
잠재적인 문제가 있다. 아래의 두 가지 경우를 살펴보자.

1. 인자 `n` 보다 `source` 가 짧은 경우
2. 인자 `n` 보다 `source` 가 길 경우

첫 번째 경우에는 `source` 가 인자 `n`보다 작은데도 불구하고 전체 `array`를
복사하게 되는 불필요한 연산이 발생할 수 있다.

두 번째 경우에는 `source` 가 인자 `n`보다 큰 경우이다. 이 경우 `destination` 은
`NULL` 로 끝나지 않게 돼 문자열로써 사용할 수 없다. 이러한 문제를 해결하기 위해
사용 버전이 `strlcpy`이다.

## strlcpy

`BSD` 계열의 커널에서는 `strncpy`를 해결하기 위해 `strlcpy`를 구현하였다.

```c
size_t strlcpy(char *dest, const char *src, size_t n);
```

프로토타입은 `strncpy`와 비슷하다. 하지만 `strncpy`와의 한 가지 차이점은
`strlcpy`는 **항상 destination 문자열이 NUL-terminated 라는 것을 보장한다**는
점이다. 그리고 반환값으로 `src`의 길이를 반환하기 때문에 `*dest`로 반환된
문자열과 비교함으로써 정상적으로 문자열 복사가 이뤄졌는지 비교할 수 있다. 하지만
당시에 비효율적이라는 이유로 `glibc` 메인테이너와 커널 개발자들에게도
`strlcpy`는 환영받지 못했다.

> This is horribly inefficient BSD crap. Using these function only leads to
other errors. Correct string handling means that you always know how long your
strings are and therefore you can you memcpy (instead of strcpy). Beside, those
who are using strcat or variants deserved to be punished.

맞는 말이긴 하다. `source` 문자열의 길이가 얼마인지 알고 있기 때문에 명시적으로
하자면 `memcpy`를 이용하면 되지 굳이 `strlcpy`를 이용해가면서 반환값을 재차
`*dest`와 비교하는 코드를 짤 필요는 없다. 하지만 이것보다 더 중요한 몇 가지
결함이 있다.

1. 실제 데이터가 복사될 수 없는 경우에도 `source` 문자열을 읽어야 한다.
2. `source` 문자열을 신뢰할 수 없는 경우(non-NUL terminated)를 처리하지 못한다.
3. race condition 이 존재한다.

`strlen` 을 이용해 전체 소스 문자열의 길이를 확인하기 위해 읽어야 하는 문제점이
존재하고, 아래와 같이 구현되어 있는 `strlcpy` 는 만약 `source` 문자열이 NUL로
끝나지 않는 상태일 경우 문제가 발생할 수 있다. 실제 아래의 코드를 보면 그러한
경우가 발생했을 때 클라이언트 쪽에서 알 수 있는 방법이 없다.

```c
size_t strlcpy(char *dest, const char *src, size_t size)
{
	size_t ret = strlen(src);

	if (size) {
	    size_t len = (ret >= size) ? size - 1 : ret;
	    memcpy(dest, src, len);
	    dest[len] = '\0';
	}
	return ret;
}
```

또한, **race condition**이 발생할 수 있다. 이 부분은 언뜻 생각하지 못한
부분인데, `src` 의 길이를 가져오고 난 뒤 중간에서 `src`가 바뀌는 경우에는 이를
처리하지 못한다.

## strscpy

```c
ssize_t strscpy(char *dest, const char *src, size_t count);
```

이러한 결점들을 해결한 함수가 바로 `strscpy`이다. 프로토타입만 보면 다른 점이
없다. 차이점은 반환값에 있다. `strlcpy`와 달리 `strscpy`는 복사된 문자들의
개수를 반환한다는 특징이 있고 실제
구현(https://elixir.bootlin.com/linux/v5.19.3/source/lib/string.c#L151)을
살펴보았을 때도 위의 간단한 문자열 복사방법과는 사뭇 다르다.

## 마치며

현재 가장 최신 버전의 `strscpy` 함수에서는 `kasan`도 함께 공부해야 완전하게
함수를 이해할 수 있을 것 같다. 이젠 하다하다 문자열 하나 복사하는 함수조차 쉽게
이해하기 힘들어질 지경까지 이르렀다. 배워도 까먹어버리니 언젠간 다시 이 글도
다시 뒤적거릴 때가 올 것이다.

## 출처
- https://lwn.net/Articles/905777/
- https://lwn.net/Articles/612244/
- https://github.com/torvalds/linux/commit/30035e45753b708e7d47a98398500ca005e02b86
