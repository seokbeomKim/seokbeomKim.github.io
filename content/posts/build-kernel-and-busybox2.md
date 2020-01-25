---
title: "Linux 커널, Busybox 빌드 후 QEMU에서 실행하기(2/2)"
date: 2019-05-23T15:10:46+09:00
categories:
- O/S
tags:
- kernel
- buildroot
- busybox
keywords:
- tech
---

지난 번 포스팅에서는 단순하기 initramfs 램디스크를 만들어 busybox에
올리는 방법을 기술했었다. 그러면서 램디스크가 무엇인지 busybox는
무엇인지, 그리고 대략적인 빌드 디렉토리 구조를 파악할 수 있었던
기회였다.

두 번째 포스팅에서는 직접 busybox를 빌드하지 않고 `crosstool-ng`라는
크로스 컴파일러 생성 스크립트 도구와 `buildroot`라는 Makefile 패키지를
이용하여 램디스크를 만드는 방법에 대해 기술하겠다.

# Crosstool-ng 이용하여 크로스 컴파일러 만들기
crosstool-ng는 미리 설정된 config를 이용해 손쉽게 크로스 컴파일러를
만들 수 있는 패키지이다. 이를 어떻게 이용하는지 자세히 설명하겠다.

먼저 crosstool-ng를 받는다. 이 때,
[깃허브](https://github.com/crosstool-ng/crosstool-ng)에 있는 경로를
이용해 직접 받아쓰는 경우가 있을텐데 만약, 받아쓰는 경우라면 반드시
릴리즈 버전으로 checkout해서 사용해야 한다. master로 그냥 받아서
사용하면 이상한데서 고생하게 된다. git을 사용하지 않는 경우는
[여기](http://crosstool-ng.org/download/crosstool-ng/)를 통해
홈페이지에서 직접 받아서 사용할 수 있다.

$ git clone https://github.com/crosstool-ng/crosstool-ng
$ git fetch --all
$ git checkout tags/crosstool-ng-1.24.0-rc3

압축을 푼 후 내부에서 아래와 갈이 설정해준다.

$ ./configure --local
$ make
$ make install

이제 크로스컴파일러를 만들어보자. 컴파일러 생성을 위해 필요한
패키지(binutls, glibc, gcc, mpc, flex..등등)들을 자동으로 다운로드하고
빌드한다. 예전 LFS(Linux from scratch)에서 이 방법을 썼다면 정말로
편하게 작업할 수 있었을텐데 하는 아쉬움이 남는 순간이었다.

아래와 같이 `list-samples` 옵션을 주어 실행하면 사용 가능한 샘플
목록들이 출력된다. 여기에 없다면 앞으로 수행할 menuconfig에서 필요한
설정들을 직접 해주어야 한다.

root@19893213a218:~/Workspaces/crosstool-ng# ./ct-ng list-samples
Status  Sample name
(생략)
...
[L...]   x86_64-multilib-linux-gnu
[L..X]   x86_64-multilib-linux-musl
[L...]   x86_64-multilib-linux-uclibc
[L..X]   x86_64-w64-mingw32,x86_64-pc-linux-gnu
[L...]   x86_64-ubuntu12.04-linux-gnu
[L...]   x86_64-ubuntu14.04-linux-gnu
[L...]   x86_64-ubuntu16.04-linux-gnu
[L...]   x86_64-unknown-linux-gnu
[L...]   x86_64-unknown-linux-uclibc
[L..X]   x86_64-w64-mingw32
[L..X]   xtensa-fsf-elf
[L...]   xtensa-fsf-linux-uclibc

 L (Local)       : sample was found in current directory
 G (Global)      : sample was installed with crosstool-NG
 X (EXPERIMENTAL): sample may use EXPERIMENTAL features
 B (BROKEN)      : sample is currently broken
 O (OBSOLETE)    : sample needs to be upgraded



커널 해킹을 위한 것이지만 임베디드용
커널을 살펴볼 것은 아니기 때문에 필자는 `x86_64-unknown-linux-gnu`를
선택하였다.

$ ./ct-ng x86_64-unknown-linux-gnu
$ ./ct-ng menuconfig # 옵션을 추가로 선택할 경우
$ ./ct-ng build

# BuildRoot 이용하여 rootfs 만들기
앞서 빌드한 크로스 컴파일러들을
/opt/crosstool/x86_64-unknown-linux-gnu 경로에 설치했다고 가정하고
`buildroot`를 이용하여 이미지 파일을 생성한다. buildroot 를 이용할
경우 크로스컴파일러를 이용해 컴파일한 응용 프로그램과 커널 모듈을 함께
빌드하여 추가할 수 있기 때문에 용이하다.

$ export BUILDROOT=$OPT/buildroot
$ export BUILDROOT_BUILD=$BUILDS/buildroot
$ mkdir -p $BUILDROOT_BUILD
$ cd $BUILDROOT_BUILD
$ touch Config.in external.mk
$ echo 'name: mini_linux' > external.desc
$ echo 'desc: minimal linux system with buildroot' >> external.desc
$ mkdir configs overlay
$ cd $BUILDROOT
$ make O=$BUILDROOT_BUILD BR2_EXTERNAL=$BUILDROOT_BUILD qemu_x86_64_defconfig
$ cd $BUILDROOT_BUILD
$ make menuconfig

이 후, 아래와 같이 설정해준다. 이 때 중요한 것은 `System configuration
---> Network interface to configure through DHCP` 부분을 빈칸으로
해줘야한다는 점이다. 기본값이 eth0으로 되어있을텐데, init 스크립트에서
해당 인터페이스가 로드될 때까지 기다리며 없을 경우에는 셸이 실행되지
않게된다.

``` text
Build options ---> Location to save buildroot config ---> $(BR2_EXTERNAL)/configs/mini_linux_defconfig
Build options ---> Download dir ---> /some/where/buildroot_dl
Build options ---> Number of jobs to run simultaneously (0 for auto) ---> 8
Build options ---> Enable compiler cache ---> yes
Build options ---> Compiler cache location ---> /some/where/buildroot_ccache
Toolchain ---> Toolchain type ---> External toolchain
Toolchain ---> Toolchain ---> Custom toolchain
Toolchain ---> Toolchain origin ---> Pre-installed toolchain
Toolchain ---> Toolchain path ---> /opt/toolchains/x86_64-unknown-linux-gnu
Toolchain ---> Toolchain prefix ---> x86_64-unknown-linux-gnu
Toolchain ---> External toolchain gcc version ---> 5.x
Toolchain ---> External toolchain kernel headers series ---> 4.3.x
Toolchain ---> External toolchain C library ---> glibc/eglibc
Toolchain ---> Toolchain has C++ support? ---> yes
System configuration ---> System hostname ---> mini_linux
System configuration ---> System banner ---> Welcome to mini_linux
System configuration ---> Run a getty (login prompt) after boot ---> TTY port ---> ttyS0
System configuration ---> Network interface to configure through DHCP --->
System configuration ---> Root filesystem overlay directories ---> $(BR2_EXTERNAL)/overlay
Kernel ---> Linux Kernel ---> no
Filesystem images ---> cpio the root filesystem (for use as an initial RAM filesystem) ---> yes
Filesystem images ---> Compression method ---> gzip
```

아래와 같이 설정 저장 후 init 스크립트를 추가해준뒤 빌드한다.

``` text
$ make savedefconfig
$ vim $BUILDROOT_BUILD/overlay/init

#!/bin/sh
/bin/mount -t devtmpfs devtmpfs /dev
/bin/mount -t proc none /proc
/bin/mount -t sysfs none /sys
exec 0</dev/console
exec 1>/dev/console
exec 2>/dev/console
cat <<!


Boot took $(cut -d' ' -f1 /proc/uptime) seconds
!
exec /bin/sh


# vim 종료 후 스크립트에 권한 부여
$ chmod +x overlay/init
$ make
```

이제 qemu를 통해 실행시켜보면 정상적으로 실행되는 것을 확인할 수 있다.

``` text
qemu-system-x86_64 -kernel $LINUX_BUILD/arch/x86_64/boot/bzImage \
  -initrd $BUILDROOT_BUILD/images/rootfs.cpio.gz -nographic \
  -append "console=ttyS0"
```

# 출처
* [Build and run minimal
  linux](https://gist.github.com/seokbeomKim/9cff93b073573fe535534c522c6e53e1)
* [Building embedded ARM systems with
  Crosstool-NG](https://briolidz.wordpress.com/2012/02/07/building-embedded-arm-systems-with-crosstool-ng/)
