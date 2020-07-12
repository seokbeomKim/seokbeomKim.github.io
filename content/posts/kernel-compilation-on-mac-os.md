---
title: "맥 OS에서 리눅스 커널 컴파일하기"
date: 2020-07-12T22:13:08+09:00
tags:
- cross compile
- kernel
- mac_os
keywords:
- Crosstool-NG
- mac os
toc: false
---

# 개요

맥 환경에서 `bare-metal`이 아닌 리눅스 커널로 컴파일하는 것은 생각했던
것보다 까다롭다. BSD 계열이기는 하지만 커널 컴파일에 필요한
라이브러리와 경로들이 리눅스 환경과 다르기 때문에, 일반적인 리눅스
배포판에서처럼 크로스 컴파일러를 바이너리 형태로 설치한 뒤에 곧바로
커널 빌드를 할 수는 없다.

이 포스팅은 맥에서 리눅스 커널을 빌드하려는 사람들을 위해 작성한
것으로, 아래 구성으로 간략하게 기술하겠다.

1. 준비 사항 및 제약 사항
2. 크로스 컴파일러 빌드
3. 커널 빌드
4. 끝맺음

본 포스팅에서 확인한 맥 환경은 아래와 같으며 단순 바이너리만 받고자
하는 경우 아래 링크에서 받도록 한다. https://github.com/seokbeomKim/armv8-rpi3-linux-gnueabihf

![](/img/my-mac.png)


# 준비 사항 및 제약 사항

맥에서 리눅스 커널을 컴파일을 할 경우에는 크로스 컴파일러를 직접
빌드해줘야 한다. 우분투와 같이 바이너리 형태로 패키지 관리자에서
제공해주는 경우에는 손쉽게 받을 수 있지만 그렇지 않은 배포판이나 맥의
경우에는 직접 만들어 사용해야 한다.

맥에서의 대표적인 패키지 매니저는 애플에서 공식적으로 제공하지는
않지만 `homebrew`이다. 이 패키지 매니저를 통해 bare-metal 크로스
컴파일러는 다운로드 할 수 있지만 GLIBC가 포함된 크로스 컴파일러는
제공되지 않으므로 라즈베리파이를 위한 커널 컴파일 시에 크로스
컴파일러를 직접 빌드해야 한다.

크로스 컴파일러 빌드 환경 구성 시 맥에서는 파티션 포맷 제약사항이
있다. **맥에서 기본으로 사용하는 파일시스템인 APFS는 기본으로
case-insensitive 이므로 반드시 case-sensitive 파티션을 추가로 구성한
후 해당 파티션에서 빌드를 진행해야 한다.** 필자는 맥 설치 시에
파티션의 포맷 자체를 case-sensitive 방식으로 지정하고 포맷해주었기
때문에 관련된 문제는 발생하지 않았다.

그리고 기본 컴파일러로서 GNU gcc가 아닌 clang을 이용하므로, `homebrew`
패키지 관리자를 통해 openssl, gcc 등을 설치해야 한다. `openssl`은
반드시 openssl@1.1을 설치한다.

``` shell
$ brew install openssl@1.1 gcc
```

# 크로스 컴파일러 빌드: ct-ng

크로스 컴파일러는 `Crosstool-NG(ct-ng)`를 이용하여 빌드한다.

``` shell
$ brew install ct-ng
$ mkdir -p ~/workspace/ct-ng-rpi3 && cd ~/workspace/ct-ng-rpi3
$ ct-ng armv8-rpi3-linux-gnueabihf
```

`armv8-rpi3-linux-gnueabihf`는 `ct-ng`에서 제공하는 샘플 중 하나로서
샘플들은 아래와 같이 확인할 수 있다.

``` shell
$ ct-ng list-samples
```

gdb 빌드 도중에 발생하는 파이썬 에러를 방지하기 위해 아래와 같이
`menuconfig`를 통해 파이썬의 바이너리 경로를 설정해주자.

``` shell
$ ct-ng menuconfig

# menuconfig 창에서 아래 설정 메뉴를 통해 파이썬 바이너리 경로를 설정한다.
Debug facilities -> gdb -> Python binary to use (/usr/bin/python)
```

또한, 필자처럼 binutils 에서 string 관련 에러가 난다면, 아래와 같이
직접 `<string>` 헤더파일을 include 하도록 수정해줘야 한다.

```
$ $home/workspace/ct-ng/rpi3b/.build/src/binutils-2.32
$ vi gold/errors.h

// 아래 include 에 <string>을 추가한다.

// MA 02110-1301, USA.

#ifndef GOLD_ERRORS_H
#define GOLD_ERRORS_H

#include <cstdarg>
#include <string>

#include "gold-threads.h"

```

크로스 컴파일러 빌드가 완료되었다면 `$HOME/x-tools` 경로 아래에
컴파일러가 생성된 것을 확인할 수 있다. 크로스 컴파일러를 빌드하면서
발생하는 에러는 맥 운영체제로 인한 것이 아니라 크로스 컴파일 환경과
타겟 gcc 버전의 호환성 문제로 인한 것이 대부분이다. 이러한 문제들은
구글링으로 관련 정보를 손쉽게 찾을 수 있다.

# 라즈베리파이 커널 빌드

이제 라즈베리파이 커널을 예로 빌드해보자. 맥에서 커널 빌드시 첫 번째로
문제가 되는 것은 `elf.h` 파일이다. 맥에서는 이 파일을 사용하지 않기
때문에 기본으로 include 경로에 포함되어 있지 않다. 빌드 시에는 필수
파일이므로,
경로(https://www.rockbox.org/tracker/task/9006?getfile=16683)에서
다운로드 하여 include 경로(`/usr/local/include`)에 추가해준다.

이제 마지막으로 라이브러리와 INCLUDE 경로를 설정해주며 빌드를 해주자.

```
$ KERNEL=kernel7 ARCH=arm make bcm2709_defconfig
$ KERNEL=kernel7 ARCH=arm HOSTCFLAGS="-I/usr/local/include -I/usr/local/opt/openssl@1.1/include -L/usr/local/opt/openssl/lib"  make -j4
```

빌드가 완료되면, 아래와 같이 커널 이미지(`zImage`)가 만들어진 것을 확인할 수 있다.

![커널 빌드 완료](/img/kernel-compilation-success.png)

# 끝맺음

위의 과정들을 하지 않고 단순하게 바이너리만 받고 싶다면
https://github.com/seokbeomKim/armv8-rpi3-linux-gnueabihf 에서 받도록
한다. 앞서 기술한 방법대로 빌드한 크로스 컴파일러로서 성능에 따라
컴파일 타임은 차이가 나지만 CPU 성능이 안좋은 경우 필자처럼 한 시간이
넘게 걸리기도 한다.

분명, 나중에 본 포스팅을 다시 참고하게 될 날이 올 것이다. 정리를 해도
매번 잊어버리는게 습관이고 매번 지난 글을 뒤적이는 게
습관이다. 하지만, 이번처럼 맥/BSD에서 리눅스의 ELF로 동작하거나
컴파일할 수 있도록 고생했던 삽질의 내용들은 되도록이면 오랫동안 기억할
수 있었으면 좋겠다.

# 참고 자료

- https://www.rockbox.org/tracker/task/9006
- https://wiki.osdev.org/GCC_Cross-Compiler
- https://github.com/raspberrypi/linux
- https://github.com/crosstool-ng/crosstool-ng/issues/844
- https://www.jaredwolff.com/cross-compiling-on-mac-osx-for-raspberry-pi/
