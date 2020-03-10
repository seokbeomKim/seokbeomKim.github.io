---
title: "IOCTL과 인터럽트"
date: 2020-03-03T00:00:10+09:00
categories:
- kernel
tags:
- ioctl
- interrupt
---

# 개요
디바이스 드라이버와 인터럽트 핸들러 간의 동기화 때문에 머리가 아팠다. 현재도 해결하지 못하고 있는 이슈가 있어 계속해서 찾아보고 있는 와중에 StackOverflow에서 재미있는 질문을 찾았다. 
- [[https://stackoverflow.com/questions/60088342/does-context-switching-occurs-when-ioctl-is-issued-from-user-space-while-kernel]]

문제 자체는 커널 모듈 안에 있는 critical section에서 스핀락을 사용하지 않을 때 irq나 softirq를 비활성화하지 않고도 데드락에 빠지지 않고 정상적으로 동작이 가능한가에 대한 질문이다. 질문에 대한 답변부터 살펴보면,

1. IRQ/SoftIRQ는 시스템 콜과 아무런 영향이 없다. 단지 인터럽트 컨텍스트 안에서 사용되는 데이터 구조들을 보호하기 위해 IRQ와 softIRQ를 비활성화하는 것 뿐이다. 

2. ioctl 시스템 호출이 일어나면 user-mode에서의 컨텍스트는 kernel-mode 컨텍스트로 진입하게 된다. 하지만 커널 모드에서 스핀락을 holding 하고 있는 경우 컨텍스트 스위칭은 일어날 수 없는데, 이유는 스핀락 자체가 preemption을 막기 때문이다. 

``` c++
static inline void __raw_spin_lock(raw_spinlock_t *lock)
{
    preempt_disable();
    spin_acquire(&lock->dep_map, 0, 0, _RET_IP_);
    LOCK_CONTENDED(lock, do_raw_spin_trylock, do_raw_spin_lock);
}
```

락을 사용하는 경우에 대해서는 좀 더 살펴봐야 하겠지만, 인터럽트 컨텍스트와 공유하는 데이터 구조들을 사용하기 위해서는 spin_lock과 같은 락을 사용하고 스핀락으로 락을 갖고 있을 때 선점될 수 없다는 점을 기억하자. 다음 포스팅에서는 러셀이 정리한 커널에서 제공하는 락의 종류가 어떨 때 사용해야 하는지를 정리해보도록 하겠다.

# 출처
- https://stackoverflow.com/questions/60088342/does-context-switching-occurs-when-ioctl-is-issued-from-user-space-while-kernel