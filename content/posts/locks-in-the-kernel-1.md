---
title: "리눅스 커널 락 종류 (1/5)"
date: 2019-05-28T17:45:51+09:00
categories:
- O/S
- Linux
- kernel
tags:
- mutex
- semaphore
- spinlock
- global kernel lock
---

리눅스 커널에서 사용되는 락의 종류는 다양하다. 학부 시절, *'뮤텍스는
세마 포어의 카운트가 1인 락'이라는 말도 안되는 내용으로 학교
선배로부터 배웠던 것이 기억난다.* 락의 종류별로 쓰임새가 있고 장단점이
있는 것인데, 이 문서에는 커널에서 사용하는 락(lock)의 종류와 각각에
대한 사용 예를 기술하고자 한다.

<!--more-->

커널에서 사용 가능한 락은 다음과 같다.

1. 스핀락(Spinlock)
2. 뮤텍스(Mutex)
3. 세마포어(Semaphore)
4. Read/Write Lock(rwlock)
5. Big Kernel Lock

# 스핀락(Spinlock)
커널 락의 주요 타입에는 스핀락(spinlock)과 뮤텍스(mutex)가
있다. 스핀락은 이름 그대로 임계구역(critical section)에 진입이
불가능할 때, 진입기 가능할 때까지 루프를 돌면서 재시도를 하는 방식으로
구현된 락을 가리킨다. 즉, 락을 획득할 때까지 해당 스레드가 계속 돌고
루핑하고 있다는 것을 의미하며, `Busy Waiting`의 한 종류이다.

 `Busy Waiting`이란, `Spinning`이라고도 하며, 특정
공유 자원에 대해 두 개 이상의 프로세스나 스레드가 그 이용 권한을
획득하고자 하는 동기화 상황에서 권한 획득을 위한 과정에서 일어나는
현상이다. 대부분 스핀락과 동일한 개념으로 사용되지만 엄밀하게
말하자면, 스핀락이 `Busy Waiting` 개념을 이용하여 구현된 것이다.

다른 락과 비교되는 스핀락의 가장 특징적인 차이점은 **운영 체제의
스케쥴링 지원을 받지 않는다는 점이다.** 즉, 락을 사용하는 스레드에
대한 문맥 교환(Context Switching)이 일어나지 않는다. 따라서 스핀락은
임계 구역에 짧은 시간 안에 진입할 수 있는 경우, 문맥 교환을 제거할 수
있어 효율적이다. 하지만 스핀락이 오랜 시간을 소요한다면 다른 스레드를
실행하지 못하고 대기하게 되어 오히려 비효율적인 결과를 가져온다.

스핀락은 아키텍처별로 어셈블리어로 구현된다. `<asm/spinlock.h>` 파일에
아키텍처별 코드가 정의돼 있으며, 실제 사용하는 인터페이스는
`<linux/spinlock.h>`에 들어있다. 이제 실제 코드를 살펴보자.

## 스핀락 커널 코드

``` c++
// 스핀락 선언
#define DEFINE_SPINLOCK(x)	spinlock_t x = __SPIN_LOCK_UNLOCKED(x)

// 스핀락을 얻는 함수 spin_lock
static __always_inline void spin_lock(spinlock_t *lock)
{
	raw_spin_lock(&lock->rlock);
}

// ...

#ifndef CONFIG_INLINE_SPIN_LOCK
void __lockfunc _raw_spin_lock(raw_spinlock_t *lock)
{
	__raw_spin_lock(lock);
}
EXPORT_SYMBOL(_raw_spin_lock);
#endif

// 아래에서도 알 수 있듯이 스핀락을 얻을 때 선점을 비활성화하고 스핀락을 거는 것을 알 수 있다.
static inline void __raw_spin_lock(raw_spinlock_t *lock)
{
	preempt_disable();
	spin_acquire(&lock->dep_map, 0, 0, _RET_IP_);
	LOCK_CONTENDED(lock, do_raw_spin_trylock, do_raw_spin_lock);
}


static __always_inline void spin_unlock(spinlock_t *lock)
{
	raw_spin_unlock(&lock->rlock);
}

// 스핀락 초기화 매크로
#define spin_lock_init(_lock)				\
do {							\
	spinlock_check(_lock);				\
	raw_spin_lock_init(&(_lock)->rlock);		\
} while (0)

```

마지막으로 `raw_spin_lock_init`을 gtags으로 계속 찾아 들어가면
`_raw_spin_lock`에 대해서 아래와 같이 `spinlock_api_up.h`과
`spinlock_api_smp.h`로 각각 구분되어 정의되어 있는 것을 알 수 있다.

```text
/Volumes/KernelHacking/Workspaces/linux-4.20.9/include/linux/spinlock_api_up.h
58: #define _raw_spin_lock(
/Volumes/KernelHacking/Workspaces/linux-4.20.9/include/linux/spinlock_api_smp.h
47: #define _raw_spin_lock(
```


**UP**는 **Uni-Processor**를, **SMP**는 **Symmetric
Multi-Processor**를 의미한다. 각각의 경우에서 스핀락을 사용할 때
생기는 문제점은 다음과 같다.  프로세서가 하나인 UP(Uni-Processor)인
경우, 스핀락으로 인한 성능 오버헤드는 상당하다. 임계영역(Critical
Section) 내에서 락을 잡고 있는 스레드가 선정됐다는 상황을
생각해보자. 이런 상황에서 스케쥴러는 스핀락을 잡고 있는 스레드 외의
다른 모든 스레드를 실행하려할 것이고 스케쥴링된 스레드는 첫 번째
스레드(임계영역을 실행하고 있던)가 쥐고 있는 락을 얻으려 하면서
불필요하게 CPU 사이클을 낭비하게 되는 문제가 발생한다.<br><br>


하지만, SMP(Symmetric Multi-Processor) 환경인 경우 스핀락은 잘 동작한다. *UP(Uni-Processor)*
환경과 달리 한 스레드가 임계영역 내에서 락을 잡고 있는 상태라도
프로세스가 여러 개이므로 앞서 설명한 상황과 같이, 다른 스레드들이
스케쥴링 되더라도 스핀락 자체가 매우 짧은 시간동안 언락된다면
스케쥴링된 새로운 스레드가 해당 락을 잡게 되어 'Uni-Processor'처럼
클럭 낭비를 줄일 수 있다.

## 스핀락과 후반부 처리

스핀락은 인터럽트 핸들러에서 종종 사용된다고 언급했다. 특히, "후반부
처리와 지연된 작업"에서 후반부 처리를 진행할 때는 락에 대해 특별한
주의를 기울여야 한다. `spin_lock_bh()` 또는 `spin_unlock_bh()` 함수와
같은 경우 지정한 락을 걸고 모든 후반부 처리 작업을 비활성화
시킨다. 이렇게 후반부 처리를 비활성화하는 이유는 **프로세스 컨텍스트
코드를 선점할 수 있기 때문이다.** 만약 후반부 처리와 프로세스 컨텍스트
간에 공유하는 데이터가 있다면 반드시 데이터를 보호하기 위해서 락을
걸고 후반부 처리를 비활성화 시켜야 한다.


# 출처
* [스핀락 --- 위키피디아](https://ko.wikipedia.org/wiki/%EC%8A%A4%ED%95%80%EB%9D%BD)
* [Different kernel flavors (UP, SMP, ENTERPRISE,
  ENTNOSPLIT)](https://wiki.openvz.org/Different_kernel_flavors_(UP,_SMP,_ENTERPRISE,_ENTNOSPLIT))
