---
title: "Linux 커널, Busybox 빌드 후 QEMU에서 실행하기(1/2)"
date: 2019-05-22T19:35:04+09:00
categories:
- Kernel
tags:
- busybox
- qemu
keywords:
- tech
---

<!-- toc -->

**취업은 언제하나...** 커널 공부를 할 게 아니라 취업을 위한 알고리즘을
공부해야 하는데 커널 해킹을 위한 환경 구축만 하고 공부하자는 것이
꼬리에 꼬리를 물게 되었다. 커널 분석을 공부하고 궁금했던 사항들을 직접
확인해보기 위해 QEMU를 이용한 환경을 구축하기로 결정했다. 다행히도
나와 같은 생각을 한 사람이 있었고 매우 자세하게 설명을 해놓았기에 금방
해결할 수 있었다. 다만, 부팅 후 램디스크만을 이용하고 루트파티션은
마운트하지 않는다는 제한은 있다.

이 문서는 참고한 페이지를 토대로 필요한 정보들을 중간에 좀 더 추가한
형태로 정리하였다. 향후 커널 분석과 토이 프로젝트들을 진행하기 위해
필요한 환경으로 실행 환경은 아래와 같다.

출처 페이지와는 다르게 필자는 맥 환경에서 커널 컴파일을 진행해야 했기
때문에 빌드를 시작하기에 앞서 docker 컨테이너를 준비하는 과정이
있었다. 맥에서 직접 크로스 컴파일러를 직접 만들어 사용하는 방법도
있지만, 시간도 오래 걸리고 빌드에 필요한 헤더 환경이 달라 도커를
사용하였다.

# 맥에서 작업하기 위한 환경 구축하기
현재 주로 사용하는 운영체제는 `macOS Mojave 10.14.5`이다. 이 환경에서
리눅스 커널을 빌드하기 위해서는 GNU GCC, GLIBC 환경이 리눅스와
일치해야 하는데 커널 컴파일을 위해 필요한 헤더파일 경로부터 맞지 않은
부분이 있어 크로스 컴파일러를 준비하는 방법은 포기하고 대신, docker를
사용하기로 했다. 가상머신을 이용하는 방법도 있지만, 도커에 비해 무겁고
GUI 환경이 불필요했기에 도커를 이용해 커널 컴파일을 하는 편이 훨씬
유리하다고 생각했다.

## 우분투 이미지로 컨테이너 생성하기
docker를 설치했다는 가정하에, 아래와 같이 컨테이너를 만들었다. 호스트
볼륨을 컨테이너에 맵핑해주었는데 이렇게 해야 커널 해킹한 소스를 바로
빌드하여 맥에서 QEMU를 통해 확인할 수 있기 때문이다.

``` shell
docker run --name kernel_builder -ti -v /Users/sukbeom/Workspaces:/kernel/ ubuntu /bin/bash
# 아래 부터는 개발 환경을 위한 패키지 설치이다.
apt update && apt upgrade
apt install vim && vim /etc/apt/sources.list # 편집기 설치 및 미러저장소 경로 설정
apt install git curl libncurses-dev wget gcc make flex build-essential bison linux-headers-generic libelf-dev openssl bc libssl-dev cpio
```

# 1. BusyBox 준비

이제 컴파일을 위한 빌드 환경이 준비되었다. 커널 컴파일을 위한 맥에서의
경로는 `$HOME/Workspaces/kernel` 로 지정하고 컨테이너 내에서는
`/kernel` 로 접근하도록 설정하였다. 커널은
[여기](https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.20.9.tar.xz)에서,
busybox는 [여기](https://busybox.net/downloads)에서 받을 수
있다. 필자가 사용한 버전은 아래와 같다.

* busybox: 1.30.1
* kernel: 4.20.9

> busybox란?<br>Single executable 파일 형태로 여러 가지 유닉스
> 유틸리티를 제공하는 Software suite 이다. 안드로이드 상에서 리눅스와
> 같은 터미널 환경을 제공하는 termux 애플리케이션을 살펴보면 최초 실행
> 시 busybox를 설치하는 것을 알 수 있다. 임베디드 환경과 같이 아주
> 제한된 리소스를 가진 시스템 상에서 필요한 (셸 환경을 위한)최소한의
> 유틸리티만을 사용하고자 할 때 사용하는 소프트웨어라고 생각하면 된다.

원래는 커널 분석을 하던 버전(v2.6.39)으로 진행을 하고자 했으나 소스
자체가 오래되었고 GCC 7 버전을 지원하지 않아 플래그와 perl 소스에서
생기는 에러를 고쳐도 컴파일 에러가 나 버전을 바꾸었다. 추후 GCC 버전을
낮춰 다시 한번 빌드 해봐야겠다.

## 1-1. BusyBox 빌드 설정
이제 컨테이너 환경으로 돌아가 아래와 같이 (shell)환경변수를 임시로 설정해준
뒤 차례대로 빌드해준다.

``` shell
STAGE=~/Workspaces
TOP=$STAGE/custom-kernel
mkdir -p $STAGE
```

다운로드 한 busybox, kernel 소스의 압축을 풀어주고 아래와 같이
busybox를 설정해준다. `Busybox settings -> Build BusyBox as a static
binary (no shared libs)` 항목에 체크해준다. *(출처 링크에 가면 친절한
스크린샷과 함께 각 과정들을 자세하게 확인할 수 있다.)*

``` shell
make O=$TOP/obj/busybox-x86 menuconfig
```

## 1-2. BusyBox 빌드 및 initramfs 디텍토리 구조 만들기

``` shell
cd $TOP/obj/busybox-x86
make -j3
make install
```

`make install`을 완료하고 나면 `_install` 이름으로 디렉토리가 생성된
것을 확인할 수 있다. 이를 이용하여 아래와 같이 `initramfs`를 생성한다.

``` shell
mkdir -pv $TOP/initramfs/x86-busybox
cd $TOP/initramfs/x86-busybox
mkdir -pv {bin,dev,sbin,etc,proc,sys/kernel/debug,usr/{bin,sbin},lib,lib64,mnt/root,root}
cp -av $TOP/obj/busybox-x86/_install/* $TOP/initramfs/x86-busybox
sudo cp -av /dev/{null,console,tty,sda1} $TOP/initramfs/x86-busybox/dev/
```

## 1-3. Init 파일 만들기
`$TOP/initramfs/x86-busybox/init` 파일을 생성한 뒤 아래와 같이 내용을 작성한다.

``` shell
mount -t proc none /proc
mount -t sysfs none /sys
mount -t debugfs none /sys/kernel/debug

echo -e "\nBoot took $(cut -d' ' -f1 /proc/uptime) seconds\n"

exec /bin/sh
```

작성 후에는 실행 권한을 조정한다:

``` shell
chmod +x $TOP/initramfs/x86-busybox/init
```

## 1-4. initramfs 생성

initramfs는 메모리 기반 디스크 구조, 즉 램디스크이다. 주요 목적은 root
파일 시스템을 마운트 하기 위한 것이며, 일반적인 root 파일 시스템에서
찾아볼 수 있는 디렉토리 구조를 갖고 있다.

일반적으로, 루트 파일시스템의 init 프로그램으로 제어권을 넘기기 전에,
필요한 파일 시스템을 마운트하는 필수 도구와 스크립트를 포함하고 있는
램디스크로서 `initramfs` 루트디스크에서 시스템을 준비하는 설정
스크립트를 준비하고 실제 파일 시스템으로 전환한 뒤 init을 실행한다.

요약하면, 실제 루트파일시스템을 마운트 하고 그 안의 init 프로그램을
실행하기까지의 준비단계를 위한 램디스크라 생각하면 된다.

> 그렇다면 그러한 램디스크는 왜 필요한 것일까? <br> 예전 젠투 리눅스를
> 이용해 리눅스를 설치했던 경험으로 ramdisk 없이도 리눅스를 충분히
> 사용할 수 있었다. 다만, 루트파티션이 암호화된 경우에는 반드시
> 램디스크를 통해 로드해야 했고 최근에는 (데스크탑용 리눅스에서)
> 이러한 램디스크가 필수적이 되어가고 있는 추세인 듯하다.

``` shell
cd $TOP/initramfs/x86-busybox
find . | cpio -H newc -o > ../initramfs.cpio
cd ..
cat initramfs.cpio | gzip > $TOP/obj/initramfs.igz
```

# 2. 커널 빌드하기
이제 busybox 준비가 끝났으니 리눅스 커널을 빌드해보자.

## 2-1. Minimal config로 리눅스 커널 설정하기

``` shell
cd $STAGE/linux-4.20.9
mkdir -pv $TOP/obj/linux-x86-allnoconfig
make O=$TOP/obj/linux-x86-allnoconfig allnoconfig
make O=$TOP/obj/linux-x86-allnoconfig -j3
```

## 빌드한 커널, busybox 함께 실행하기

``` shell
qemu-system-x86_64 \
    -kernel $TOP/obj/linux-x86-allnoconfig/arch/x86/boot/bzImage \
    -initrd $TOP/obj/initramfs.igz \
    -nographic -append "earlyprintk=serial,ttyS0 console=ttyS0"

```

정상적으로 커널이 로드되고 셸이 실행된 것을 확인하면 `Control-a x`를
입력하여 QEMU를 종료한다.


# 출처
* [Build the linux kernel and busybox and run them on
  qemu](https://www.centennialsoftwaresolutions.com/blog/build-the-linux-kernel-and-busybox-and-run-them-on-qemu)
* [LFS - About initramfs](http://www.linuxfromscratch.org/blfs/view/svn/postlfs/initramfs.html)
* [Gentoo Linux - initramfs](https://wiki.gentoo.org/wiki/Initramfs/Guide/ko)
* [Build 'Mini Linux' Instruction - forked](https://gist.github.com/seokbeomKim/9cff93b073573fe535534c522c6e53e1)
