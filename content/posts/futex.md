---
title: "Futex"
date: 2020-04-02T01:45:50+09:00
categories: 
- kernel
tags:
- futex
toc: false
---

## Futex (Fast Userspace Mutexes)

futex는 전통적인 UNIX 커널에서 사용되고 있는 sleep/wakup과 매우 비슷한 동기 기구를 userland에 대해 제공한다. 주로 NPTL(Native POSIX Thread Library) 등의 라이브러리의 구현에 사용되기 때문에 애플리케이션으로부터 직접 이용하는 경우는 별로 없다고 생각되지만 POSIX Thread는 Java 스레드의 구현 등에도 이용되고 있어 동기 처리를 많이 이용하는 애플리케이션에는 이익이 있을 것이다. futex 시스템 콜의 주된 기능은 FUTEX_WAIT와 FUTEX_WAKE이다.

### pthread_mutex_lock

1. 아토믹 명령을 사용하여 lock을 시도
2. 1에서 lock이 성공되면 종료
3. FUTEX_WAIT를 사용하여 pthread_mutex_t의 주소 상에서 슬립한다
4. 시동 후, 1로 돌아간다

### pthread_mutex_unlock

1. 아토믹 명령을 사용해 unlock 처리를 실시
2. 1의 결과, 슬립하고 있는 스레드가 있다면 FUTEX_WAKE를 사용하여 wakeup한다.

## 참고

- <https://miruel.tistory.com/entry/FutexSpinlock-%EC%86%8C%EA%B0%9C%EC%99%80-%EB%AA%B0%EB%9E%90%EB%8D%98-%EC%82%AC%EC%8B%A4>
