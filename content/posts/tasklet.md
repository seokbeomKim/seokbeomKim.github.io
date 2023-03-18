---
title: "태스크릿(Tasklet)"
date: 2019-05-25T17:32:26+09:00
categories:
- Kernel
tags:
- tasklet
keywords:
- tech
---

커널 모듈 프로그래밍을 연습하던 도중, 태스크릿 예제를 접하게
되었다. 한참 전에 태스크릿이 어떤 것인지 이론으로 접하기는 했으나 직접
사용해본 적은 없었기 때문에 이 문서를 통해 정리하고자 한다.

간단히 말해 `tasklet`은 스택이나 자체 컨텍스트가 없는 스레드와 같은
것으로 설명하고 있다.

# 태스크릿(Tasklet)의 특성
* 태스크릿(tasklet)은 원자성을 가지고 있기 때문에 mutex, semaphore와
   같은 동기화 수단을 사용하거나 sleep() 을 사용할 수 없다. 단,
   `spinlock`은 가능하다.
* ISR보다 유연한 컨텍스트(softer context)로 불린다. 때문에 태스크릿의
   컨텍스트 도중 하드웨어 인터럽트가 발생하는 것을 허용한다.
* 한번에 한 프로세서에 할당되어 실행되며 여러 개에 병렬적으로 실행될
   수 없다.
* 태스크릿은 비선점 스케쥴링 방식으로 하나씩 순서대로 스케쥴링된다.

원자성(atomic)은 (물리학에서의 의미가 아닌 문자
그대로의 의미로) '더이상 나눌 수 없는 것'이다. 즉, 어떤 연산에 대해
더이상 나눌 수 없는 것 또는 한 번에 처리되어야 하는 것을 말하는데,
흔히 데이터베이스의 트랜잭션을 떠올리면 된다. 인터럽트와 선점
스케쥴러를 사용하는 리눅스 커널에서는 어떤 연산(operation)을
수행하는데, 해당 연산이 다른 것에 의해 선점되거나 방해받을 수
있다. 이럴 때, 해당 연산이 'Atomic'인 경우, 해당 연산이 다른 것에 의해
방해될 수 없으며 연산의 실패 또는 롤백의 단위가 오로지 연산 자체임을
보장하게 된다.


# 태스크릿 구조 살펴보기
struct tasklet_struct
{
    struct tasklet_struct *next;  /* The next tasklet in line for scheduling */
    unsigned long state;          /* TASKLET_STATE_SCHED or TASKLET_STATE_RUN */
    atomic_t count;               // Responsible for the tasklet being activated or nothing
    void (*func)(unsigned long);  // The main function of the tasklet
    unsigned long data;           // The parameter func is started with
};

태스크릿은 아래의 매크로를 이용하거나 init 함수를 사용하여 초기화한다.

extern void tasklet_init(struct tasklet_struct *t,
			 void (*func)(unsigned long), unsigned long data);

#define DECLARE_TASKLET(name, func, data) \
struct tasklet_struct name = { NULL, 0, ATOMIC_INIT(0), func, data }

#define DECLARE_TASKLET_DISABLED(name, func, data) \
struct tasklet_struct name = { NULL, 0, ATOMIC_INIT(1), func, data }

태스크릿은 우선순위에 따라 단방향 링크드 리스트로 구성된 큐에 삽입되며
해당 큐는 각 CPU별로 할당된다.

# 태스크릿 상태
태스크릿이 스케쥴링되면 상태는 `TASKLET_STATE_SCHED`로 설정되고 큐에
삽입된다. 일단 태스크릿이 한번 이 상태에 있게 되면, 다시 스케쥴 될 수
없다. 태스크릿이 `TASKLET_STATE_RUN` 상태에 있게 되면 스케쥴이었던
상태가 제거되며 이 상태에 있게 되면 해당 스케쥴링을 스케쥴할 수 있게
된다.

# 출처
* [Multitasking in the linux kernel interrupts and
  tasklets](https://kukuruku.co/post/multitasking-in-the-linux-kernel-interrupts-and-tasklets/)
