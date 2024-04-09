---
draft: true
title: "Tasklet"
date: 2022-11-13T17:32:26+09:00
categories:
- Kernel
tags:
- tasklet
keywords:
- tech
---

# 개요
사내 커널 스터디에서 교재로서 사용하고 있는 디버깅을 통해 배우는 리눅스 커널의
구조와 원리 책에서는 태스크릿 (Tasklet)을 SoftIRQ와 함께 아래와 같이 설명한다.

SoftIRQ 서비스 중 하나로 동적으로 Soft IRQ 서비스를 쓸 수 있는 인터페이스이다.
그리고 이와 함께 Tasklet의 실행 단계에 대한 내용이 자세하게 기술되어 있다.

인터럽트 핸들러에서 task_schedule() 함수를 호출해 태스크릿 스케쥴링을 실행한다.
task_schedule() 함수는 raise_softirq_irqoff() 함수를 호출해 TASKLET Soft IRQ
서비스를 요청한다. Soft IRQ 서비스 핸들러를 호출하는 __do_softirq() 함수에서
태스크릿 서비스 핸들러인 tasklet_action() 함수를 호출한다. Soft IRQ 서비스
핸들러를 실행한 후 실행 시간을 체크해 ksoftirqd 를 깨우고 실행을 마무리한다.
ksoftirqd 스레드에서 태스크릿 서비스 핸들러인 tasklet_action() 함수를 호출한다.
tasklet_action() 함수에서 태스크릿 핸들러 함수를 호출한다. 책에서는 SoftIRQ를
인터럽트 후반부를 빨리 처리해야 할 때 사용하는 기법으로 설명하고 있고 디바이스
드라이버에서 SoftIRQ를 사용하는 방법으로서 Tasklet 서비스를 설명하고 있다.
그런데 예전 소스 코드 기반이라 그런지 찾아본 내용과 다른 부분이 있다. 최신
코드를 기준으로 찾아보면 tasklet에 대해 아래와 같이 설명한다.

/* Tasklets --- multithreaded analogue of BHs.

   This API is deprecated. Please consider using threaded IRQs instead:
   https://lore.kernel.org/lkml/20200716081538.2sivhkj4hcyrusem@linutronix.de

   Main feature differing them of generic softirqs: tasklet
   is running only on one CPU simultaneously.

   Main feature differing them of BHs: different tasklets
   may be run simultaneously on different CPUs.

   Properties:
   * If tasklet_schedule() is called, then tasklet is guaranteed
     to be executed on some cpu at least once after this.
   * If the tasklet is already scheduled, but its execution is still not
     started, it will be executed only once.
   * If this tasklet is already running on another CPU (or schedule is called
     from tasklet itself), it is rescheduled for later.
   * Tasklet is strictly serialized wrt itself, but not
     wrt another tasklets. If client needs some intertask synchronization,
     he makes it with spinlocks.
 */

$linux/include/linux/interrupt.h

코드에서는 태스크릿 대신 Threaded IRQ를 사용할 것을 권한다. 코멘트의 링크를
따라가보면 태스크릿 매크로를 수정한 건에 대한 패치에서 태스크릿을 별도의
작업(refactor all tasklet users into other APIs · Issue #94 · KSPP/linux)으로
제거하자는 얘기가 나온다. 논의 내용을 잘 정리한 LWN 기사(Modernizing the tasklet
API [LWN.net]) 도 찾을 수 있었는데 간단하게 정리해보면 아래와 같다.

Threaded IRQ 도 atomic context에서 실행되므로 tasklet을 대체될 수 있다. 코어
개발자들도 태스크릿의 API를 개선하는 것보다 제거하는 게 더 큰 작업이지만 next
step 으로 제거하는 데에는 동의하였다. LWN 에서 이전에 다룬 내용이지만 태스크릿은
software interrupt mode에서 실행되기 때문에 다른 highest-priority 태스크들을
블록할 수 있는 latency 제한 문제가 있다. Tasklet은 workqueues, timers, threaded
interrupts로 대체 가능하다. Threaded irq를 사용하면 인터럽트 핸들러 자체에서
실행될 수 있다. 그리고 이러한 신규 매커니즘들은 태스크릿의 단점들이 없기 때문에
굳이(?) 개발자들이 tasklet 을 쓸 이유가 없다. 결론적으로 태스크릿을 꼭
써야한다면 어쩔 수 없겠지만 이후에 새로 나온 방법들로도 충분히 BH 를 다룰 수
있으며 이러한 방법을 제외하고 굳이 써야하는 이유는 없다는 것이다. 태스크릿을
반드시 써야 하는 경우를 판단해야 한다면 아래 링크들과 교재 내용을 함께
참고해보자.

# 참고
- Modernizing the tasklet API [LWN.net]
- Re: [PATCH 0/3] Modernize tasklet callback API - Allen (kernel.org)
