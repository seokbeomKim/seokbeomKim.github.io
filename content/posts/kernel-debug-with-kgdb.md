---
title: "Kernel Debug With Kgdb"
date: 2021-04-13T23:31:41+09:00
draft: false
categories:
- kernel
tags:
- kgdb
---

# 개요

필자에게는 디버깅이 현업에서 가장 많은 시간을 소모하는 일이다. 업무 효율을
위해서 디버깅 하는 방법을 찾던 도중 커널에서 제공하는 kdb와 kgdb를 이용하는
방법에 대한 세미나를 보게 되었다. 유투브에서 [«Using Serial kdb / kgdb to Debug
the Linux Kernel - Douglas Anderson,
Google»](https://www.youtube.com/watch?v=HBOwoSyRmys) 검색한 영상인데, KDB와
KGDB 활용하는 방법에 대해 상세하게 설명하고 있다. 본 포스팅에서는 링크의 영상을
테스트 하기 위해 필요한 디버깅 환경 구성 방법에 대해서만 간단하게 정리한다.

KDB/KGDB 를 이용하는 방법은 Trace32 를 이용하여 디버깅할 수 없는 환경에서 매우
유용하다. 타겟 보드에 따라 JTAG 디버깅 포트가 나와있지 않은 경우도 꽤 있기
때문이다. 한 가지 단점으로는 디버깅 환경 구성이 생각보다 복잡하다.

환경 구성을 위해 필요한 작업은 아래와 같다.

1. De-muxing Serial communication (kdmx)
2. Kernel configuration
3. Attaching GDB

# Demuxing Serial Communication using kdmx

필자는 라즈베리파이를 이용하여 디버깅 환경을 구성했다. 호스트가 리눅스
랩탑이었으면 좋았겠지만, 안타깝게도 맥 OS 환경을 사용하였다. 타겟 보드와 시리얼
통신을 한다는 가정 하에, GDB와 터미널 환경을 하나의 시리얼 포트로 연결하기
위해서는 가상 시리얼 포트를 생성하고 통신을 De-mux 해주는 프로그램이
필요하다. 그리고 이를 위한 간단한 도구가 kdmx이다. 본래 agent-proxy 라는
프로젝트 밑에 간단한 프로그램 형태로 들어가 있지만, 손쉽게 받아서 별도의 환경
변수 설정 없이 곧바로 빌드가 가능하다.

ioctl을 사용하지 않는 BSD 계열에서는 약간의 수정사항이 필요하지만 필자가
올려놓은 저장소 내의 코드(https://github.com/seokbeomKim/kdmx)를 이용하면
된다. 리눅스 계열이라면,
git://git.kernel.org/pub/scm/utils/kernel/kgdb/agent-proxy.git 에서 다운받아서
사용하도록 하자.

kdmx 를 빌드한 뒤에 아래와 같이 실행해주면, pseudo tty가 만들어진 것을 확인할 수
있다.

``` bash
┌─[sukbeom@Sukbeomui-MacBookPro] - [~/Workspaces/kdmx/kdmx] - [3061]
└─[$] ./kdmx -p /dev/tty.usbserial-0001 -b 115200                                                                         [23:37:07]
/dev/ttys000 is slave pty for terminal emulator
/dev/ttys003 is slave pty for gdb

Use <ctrl>C to terminate program
```

테스트를 위해 /dev/ttys000 를 열어 아래와 같이 확인해보자.

``` text
$ minicom -D /dev/ttys000 -b 115200

Welcome to minicom 2.8

OPTIONS:
Compiled on Jan  4 2021, 00:04:46.
Port /dev/ttys000, 23:52:43

Press Meta-Z for help on special keys
```

# Kernel Configuration

아래의 커널 설정 플래그들을 확인한다. 커널 컴파일 하는 방법은 디버깅 환경 구성과
다른 내용이므로 이 포스팅에서 자세하게 설명하지 않겠다.

``` text
CONFIG_KGDB_KDB=y
CONFIG_KDB_DEFAULT_ENABLE=0x1
CONFIG_KDB_KEYBOARD=y
CONFIG_KDB_CONTINUE_CATASTROPHIC=0
# CONFIG_WATCHDOG is not set
# CONFIG_WQ_WATCHDOG is not set
CONFIG_MAGIC_SYSRQ=y
CONFIG_MAGIC_SYSRQ_DEFAULT_ENABLE=0x1
CONFIG_MAGIC_SYSRQ_SERIAL=y
CONFIG_MAGIC_SYSRQ_SERIAL_SEQUENCE="."
```

# Attaching GDB

이제 KGDB를 직접 이용해보자. 필자는 컴파일용 리눅스 서버에서 커널을 빌드하고
생성된 vmlinux 파일을 Mac OS에 복사하여 심볼을 로드하는데 사용하였다. 맥용 gdb가
필요하다면 반드시 https://seokbeomkim.github.io/posts/kernel-hacking-on-mac/
포스팅을 참고하도록 한다. (homebrew 를 이용하여 gdb 를 설치해봤자 정상적으로
동작하지 않으니 반드시 포스팅에 기술된대로 직접 GDB를 빌드해 사용해야 한다.)
우분투와 같은 데비안 계열이라면 gdb-multiarch를, 아치리눅스라면 AUR 내에 있는
컴파일러 패키지들을 이용하자.

먼저, kdmx 를 이용하여 시리얼 통신이 제대로 demuxing 되고 있다는 가정 하에
진행한다. 단순하게 kgdb의 동작을 테스트할 목적이므로, sysrq 를 이용하여 kdb에
진입하여 kgdb를 붙인 뒤 고의로 커널 패닉을 발생시켜 gdb로 어떻게 분석 가능한지를
보일 것이다.

먼저, kgdb 에서 사용할 시리얼을 아래와 같이 설정해준다.

``` bash
root@raspberrypi:/home/pi# who | awk '{print $2}' > /sys/module/kgdboc/parameters/kgdboc
root@raspberrypi:/home/pi# cat /sys/module/kgdboc/parameters/kgdboc
ttyS0
```

이제 sysrq 를 이용하여 KDB로 진입한 뒤 kgdb 를 실행한다.

``` bash
root@raspberrypi:/home/pi# echo g > /proc/sysrq-trigger
[ 1141.184978] sysrq: DEBUG

Entering kdb (current=0x836b8000, pid 552) on processor 0 due to Keyboard Entry
[0]kdb>

[0]kdb>
[0]kdb> kgdb
Entering please attach debugger or use + or

```

이제 호스트에서 GDB를 실행한 뒤 시리얼 통신으로 붙여준다. 아래와 같이 정상적으로
attach 가 된 것을 알 수 있다.

``` bash
$ ./arm-linux-gnueabihf-gdb ~/Workspaces/rpi/vmlinux
(gdb) file ~/Workspace/rpi/vmlinux
(gdb) cd /Volumes/Kernel/rpi_kernel
(gdb) target remote /dev/ttys003
Remote debugging using /dev/ttys003
warning: multi-threaded target stopped without sending a thread-id, using first non-exited thread
[Switching to Thread 4294967294]
arch_kgdb_breakpoint () at ./arch/arm/include/asm/kgdb.h:46
warning: Source file is more recent than executable.
46		asm(__inst_arm(0xe7ffdeff));
(gdb)
```

# 끝맺음

현업에서 다른 사람들의 디버깅 방법을 보면서 가장 답답한 부분은 디버깅 시에 툴을
사용하지 않는다는 점이다. 몇몇 스타 개발자의 경우 디버깅 툴을 싫어하고 로그
메시지만으로도 충분하다고 하는데 개인적으로는 이러한 의견에 반대한다. 로그
메시지를 이용하여 문제를 해결하는 방향을 세우고 분석하는 것도 중요하지만, 그러한
문제 해결에 도움을 주는 도구를 이용하여 불필요한 시간을 줄이는 것도
중요하다. 물론, 그들처럼 똑똑하지 않은 것도 중요한 이유다.
