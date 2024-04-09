---
draft: true
title: "WARN_ON, BUG_ON 매크로"
date: 2020-02-21T00:12:34+09:00
categories:
- kernel
tags:
- WARN_ON
- BUG_ON
---

# 개요
업무 중에 예전 SDK에서 커널 패닉이 일어나는 것을 보고 관련 코드를
살펴보니, `BUG_ON` 매크로 사용에 의한 것으로 파악했다. 커널 패닉을
일으킬 정도로 크리티컬은 아니었기에 해당 매크로를 `WARN_ON`으로
변경하였다. 변경 이후에 커널 패닉은 일어나지 않았지만 커널 메시지로
보여주는 내용이 조금 달랐다. 

이 글에서는 `BUG_ON`, `WARN_ON` 등 커널에서 제공하는 `assertion`에
해당하는 매크로가 어떤 것들이 있는지 살펴보고 **어떤 경우에 사용해야
하는지에 대해 간략히 정리하고자 한다**. 이 외에 커널에서는
`dump_stack()`, `save_stack_trace()`, `dump_trace()`, `backtrace()`
등의 콜 스택 출력 방법을 제공한다.

# WARN_ON, BUG_ON
출처에 따르면, 리눅스 디바이스 드라이버에서 가장 빈번하게 나타나는
매크로는 `BUG_ON/BUG`와 `WARN_ON`이라고 설명하고 있다.

``` c++
BUG_ON(condition)
// 또는
if (condition)
	BUG()
```

위 예시처럼 매크로를 사용할 수 있으며 각각의 매크로가 하는 역할은
다음과 같다.

## BUG()
- 레지스터 내용 출력
- Stack Trace 출력
- 커널 패닉 발생

## WARN()
- 레지스터 내용 출력
- Stack Trace 출력

`linux/include/asm-generic/bug.h` 파일을 살펴보면 BUG() 매크로에 대해
아래와 같이 주석을 달아놓은 것을 확인할 수 있다. 정말로 대안이 없을
경우에만 사용하도록 하며, 정말로 복구할 방법이 없을 때에만 사용하도록
하자.

``` c++
/*
 * Don't use BUG() or BUG_ON() unless there's really no way out; one
 * example might be detecting data structure corruption in the middle
 * of an operation that can't be backed out of.  If the (sub)system
 * can somehow continue operating, perhaps with reduced functionality,
 * it's probably not BUG-worthy.
 *
 * If you're tempted to BUG(), think again:  is completely giving up
 * really the *only* solution?  There are usually better options, where
 * users don't need to reboot ASAP and can mostly shut down cleanly.
 */
```


# 출처
- http://embeddedguruji.blogspot.com/2018/12/bugon-vs-warnon-macros-in-linux-kernel.html
- https://dreamlog.tistory.com/343
