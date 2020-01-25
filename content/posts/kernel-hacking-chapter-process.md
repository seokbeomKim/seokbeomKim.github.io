---
title: "커널 해킹: 프로세스"
date: 2019-05-16T18:59:15+09:00
categories:
- O/S
tags:
- process
- linux kernel
keywords:
- tech
---

앞으로 리눅스 커널 공부를 해가면서 포스팅으로 정리해둘
계획이다. 디바이스 드라이버 개발 이전에 리눅스라는 운영체제에 대해
개인적으로 정리해야할 필요성을 느꼈다. 그리고 최신 커널을 사용하기
보다 상대적으로 오래된 커널을 시작으로 공부하고자 한다. 기본 틀은 크게
변하지 않았을거라 생각하고 충분히 이해한 뒤에 최근 버전을 받아 개발
흐름을 이해하는 것이 옳은 방법이라 생각하였다.

이 문서에서는 리눅스/유닉스 운영체제의 기본 추상화 개념 중 하나인
프로세스에 대해 정리하고자 한다. 정리에 필요한 정보 수집을 위해서
Linux kernel development(3rd edition) 책과 LWN 등의 사이트들을
참고한다.

문서는 계속해서 업데이트할 예정이며, 내용이 추가되면 문서를 분리하거나
링크를 통해 업데이트할 예정이다.

# 프로세스(Process)란?
프로세스는 실행 중인 프로그램으로 다음과 같은 리소스들을 포함한다.

## 프로세스 디스크립터, PCB
프로세스 디스크립트(Process Descriptor)는 Task Descriptor 또는 Process
Control Block이라고도 불린다. 프로세스의 전반적인 정보들을 담고 있으며
대표적인 것들은 아래와 같다.

1. 프로세스가 사용 중인 파일

    ```c++
    struct files_struct *files;
    ```

    파일 디스크립터 테이블을 포함한다. 이 정보는 태스크(프로세스를 커널
   내부에서는 Task라 일컫는다.) 간에 공유할 수 있으며 `CLONE_FILES`를
   이용해 특정할 수 있다.
2. 파일시스템 정보

    ```c++
    struct fs_struct *fs;
    ```

    처음 소스를 보자마자 이해하기 어려운 부분이었다. 어째서 프로세스가
   파일시스템 정보까지 가지고 있어야 하는가? 출처에서 이 부분은 아래와
   같이 설명하고 있다.<br><br>

   * root directory's dentry and mountpoint.
   * alternate root directory's dentry and mountpoint.
   * current working directory's dentry and mountpoint.

    즉, `ext4, xfs` 와 같은 파일시스템의 정보가 아니라 프로세스 실행
   환경을 위한 루트 디렉토리의 엔트리 정보와 마운트 포인트 정보를 가지고
   있는 것이다. 이 부분에 대해서는 나중에 좀 더 알아봐야겠다.
2. 대기 중인 시그널과 시그널 핸들러

    ```c++
    struct signal_struct *signal;
    struct sighand_struct *sighand;
   ```
   파일시스템 정보와 마찬가지로 `clone` 된 태스크들과 공유할 수 있는
   정보이며 `CLONE_SIGHAND`를 통해서 특정할 수 있다.

3. 프로세서 상태

    ```c++
    /* -1 unrunnable, 0 runnable, >0 stopped */
    volatile long state;
    ```

    프로세스의 상태를 `volatile`이라는 키워드와 함께한 변수로 담고
    있으며 단순하게 unrunnable, runnable, stopped 등으로 구분하고
    있다.

    > 여기서 `volatile`은 왜 사용된 걸까? TLDP 출처에는 "The volatile
    > in p->state declaration means it can be modified asynchronously
    > (from interrupt handler) 라고 설명되어 있다. 그런데 [커널
    > 문서](https://www.kernel.org/doc/html/latest/process/volatile-considered-harmful.html)를
    > 살펴보면 "volatile" 타입 클래스를 사용해서는 안되는지에 대한
    > 설명이 나와있는데 실제로 state 변수를 제외하고는 sched.h 나머지
    > 어디에도 사용되고 있지 않다. 그 이유는 다음과 같다:
    >
    > volatile의 목적은 최적화를 막는 것이다. 커널은 데이터 구조들을
    > 원치 않은 동시 접근(concurrent access)로부터 철저하게 보호해야
    > 하는데 그러한 보호 과정으로 최적화에 관련된 문제들을 더 효과적인
    > 방법으로 피해갈 수 있다.
    >
    > volatile과 같이 커널에는 동시 접근으로부터 데이터를 보호하기
    > 위해 spinlocks, mutexes, memory barriers 등으로 원치 않은
    > 최적화를 막기 위해 설계했다. 문서에는 "그러한 설계된 도구들을
    > 충분히 잘 활용할 수 있다면 volatile을 사용할 이유가 없고,
    > volatile이 여전히 필요하다면 대부분 코드 어딘가에 버그가 내재된
    > 것이다" 라고 설명하고 있다.
    >
    > 하지만, 프로세스 상태와 같이 멀티 프로세스 환경에서 반드시 여러
    > 개의 쓰레드에 공유되어야 하는 변수들은 volatile을 사용하여
    > 컴파일러가 최적화하는 것을 막는다.

    프로세스의 상태는 매크로 형태로 정의되어 있다. 커널
    버전(5.x)에서는 값들이 Hex 값으로 정의되어 있는 반면, 2.6.x
    버전에서는 단순히 정수형으로 정의되어 있다. 이전 커널과의 주요
    차이점은 Task의 상태를 `TASK_RUNNING`, `TASK_INTERRUPTIBLE`,
    `TASK_UNINTERRUPTIBLE`, `TASK_DEAD`, `TASK_WAKEKILL`,
    `TASK_WAKING` 등으로 구분하고 종료 시점의 상태를 별도로 구분하여
    `EXIT_ZOMBIE`, `EXIT_DEAD` 등으로 정의해 놓았다는 점이다.

4. 하나 이상의 물리적 메모리 영역이 할당된 메모리 주소 공간

    메모리 관리용 데이터 구조로서(객체라는 말은 사용하지 않겠다.)
   task_struct 안에는 해당 정보들을 받아올 수 있는 `mm_struct`를
   포함하고 있다.

    ```c++
    struct mm_struct *mm, *active_mm;
    ```
5. 실행 중인 하나 이상의 스레드 정보

    ```c++
    /* CPU-specific state of this task */
    struct thread_struct thread;
    ```

     역시 다른 정보들과 마찬가지로 thread에 대한 정보를 가지고
    있다. 리눅스에서는 프로세스와 스레드를 구분하지 않고 모두 스레드로
    관리하고 스케쥴링한다. 둘의 차이점은 공유 자원을 다른 스레드와
    공유하느냐 공유하지 않느냐에 따라 구분하며, 프로세스가 생성되면
    커널 내부에서는 프로세스가 아닌 스레드 한 개가 생성된 것과 같다.

# 출처
* https://www.tldp.org/LDP/tlk/tlk.html
* https://www.tldp.org/LDP/lki/lki-2.html
* Linux Kernel Development 3rd edition
* https://www.kernel.org/doc/html/latest/process/volatile-considered-harmful.html
