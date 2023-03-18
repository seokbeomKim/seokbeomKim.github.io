---
title: "리눅스 커널 락 종류 (4/5)"
date: 2019-06-04T16:40:28+09:00
categories:
- Computer Science
tags:
- BKL
keywords:
- tech
---

BKL(Big Kernel Lock)은 커널 2.0에서 SMP와 함께 소개된 락으로서
Giant-Lock, Big-Lock 또는 Kernel-Lock 으로 알려졌었다. 2.0
버전의 커널에서는 한 번에 하나의 스레드만이 커널 모드에서 동작하기
위해 락(Lock)을 획득해야 커널 모드로 진입되었고 나머지 프로세서들은
락을 획득하기 위해 대기한다. 하지만 이 후, 성능, 실시간 애플리케이션에
대한 latency 이슈로 BKL(Big Kernel Lock)은 스핀락과 뮤텍스, RCU 등으로
대체되면서 현재는 거의 관련 코드가 제거되어 있는 상태이다.

  * lock_kernel(): Acquires the BKL
  * unlock_kernel(): Releases the BKL
  * kernel_locked(): Returns nonzero if the lock is held and zero
    otherwise (UP always returns nonzero)

BKL은 프로세서들이 동시에 커널에 진입하는 것을 막아 동기화 문제를 해결한다.

![BKL 동기화](/img/bkl.png)

# 출처
* http://jake.dothome.co.kr/bkl/
* https://www.kernel.org/doc/Documentation/RCU/whatisRCU.txt
