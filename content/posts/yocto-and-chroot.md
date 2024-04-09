---
draft: true
title: "Chroot 환경을 이용한 Yocto 환경 구성"
date: 2020-02-01T23:27:45+09:00
categories:
- yocto
tags:
- yocto
- bitbake
- chroot
---

# 우분투 버전과 Yocto 버전
AGL (Automotive Grande Linux) 라는 오픈소스 프로젝트에 참여해보기 위해 개발
환경을 구성하였다. 작업 환경은 가장 최신 버전의 우분투 21.10 버전으로
구성하였다. 개인적으로 Rolling Release 배포판인 아치리눅스나 젠투 리눅스들을
선호하지만 사용자가 많고 프로젝트 대부분에서 데비안 타입의 패키징을 지원하므로,
익숙한 우분투를 사용하기로 했다.

한 가지 중요한 것은 우분투의 경우 각 버전마다 빌드 환경이 다르고, Yocto의 경우
이러한 빌드 환경에 의존성을 가지고 있다는 것이다. 처음 Ubuntu 21.10 버전에서
레시피를 빌드했을 때 아래와 같은 에러 메시지에 맞딱드렸다.

``` text
In file included from ../include/QtCore/qfloat16.h:1,
	from ../include/QtCore/../../../git/src/corelib/global/qendian.h:44,
	from ../include/QtCore/qendian.h:1,
	from /home/sukbeom/Workspace/AGL/build/tmp/work/x86_64-linux/qtbase-native/5.14.2+gitAUTOINC+3a6d8df521-r0/git/src/corelib/codecs/qutfcodec.cpp:43:
../include/QtCore/../../../git/src/corelib/global/qfloat16.h:295:7: error: ‘numeric_limits’ is not a class template
295 | class numeric_limits<QT_PREPEND_NAMESPACE(qfloat16)> : public numeric_limits<float>
|       ^~~~~~~~~~~~~~
../include/QtCore/../../../git/src/corelib/global/qfloat16.h:295:77: error: expected template-name before ‘<’ token
295 | class numeric_limits<QT_PREPEND_NAMESPACE(qfloat16)> : public numeric_limits<float>
|                                                                             ^
../include/QtCore/../../../git/src/corelib/global/qfloat16.h:295:77: error: expected ‘{’ before ‘<’ token
../include/QtCore/../../../git/src/corelib/global/qfloat16.h:333:18: error: ‘numeric_limits’ is not a class template
333 | template<> class numeric_limits<const QT_PREPEND_NAMESPACE(qfloat16)>
|                  ^~~~~~~~~~~~~~
../include/QtCore/../../../git/src/corelib/global/qfloat16.h:333:69: error: ‘std::numeric_limits’ is not a template
333 | template<> class numeric_limits<const QT_PREPEND_NAMESPACE(qfloat16)>
```

이 문제는 Yocto의 빌드 환경에 대한 의존성 때문이었다. 그리고 이를 해결하기 위해
필요한 것이 바로 chroot 이다. 시스템을 구성하는 coreutils, binutils, gcc, ...
등의 패키지들은 우분투의 경우 버전 별로 다르게 구성되어 있고 각 패키지들끼리도
서로에 대해 어느 정도 의존성을 가진다. 일반적으로 chroot은 리눅스를 처음 설치할
때, LiveCD 환경에서 새로 설치하는 패키지들을 빌드하기 위한 임시 환경을
구성하거나 툴체인을 빌드하기 위한 임시 환경을 구성할 때 사용한다. 위의 문제도
Yocto 버전에 따라 요구하는 빌드 환경이 있으니 서버에 설치되어 있는 시스템에서
chroot을 위한 fakeroot 환경을 구성해주면 된다. 다행이도 우분투에서는 이를 위해
`debootstra` 이라는 것을 이용하여 간단하게 환경을 만들 수 있었다.

# chroot 환경 구성

**debootstrap 이용하기**

chroot 하기 위한 임시 rootfs 구조를 debootstrap 명령어를 이용하여 구성한다. 이
때 중요한 것은 focal 대신에 다른 릴리즈된 이름으로 변경 가능하다는 점이다.
https://wiki.ubuntu.com/Releases 페이지를 참고하여 변경하고자 하는 우분투
버전으로 임시 시스템 환경을 구성한다.

``` bash
$ sudo debootstrap --variant=buildd focal AGL-chroot
$ sudo mount -t proc /proc AGL-chroot/proc
$ sudo mount --rbind /sys/ AGL-chroot/sys
$ sudo mount --rbind /dev AGL-chroot/dev
$ sudo chroot AGL-chroot /bin/bash
```

**sources.list 수정하기**

chroot 환경에서 필요한 build 패키지들을 설치하기 위해 아래와 같이 sources.list
를 변경한다.

``` bash
$ root@sukbeom-P65-67HSHP:~# vi /etc/apt/sources.list
deb http://ftp.daum.net/ubuntu focal main
deb http://ftp.daum.net/ubuntu/ focal universe
```

**builduser 생성하기**

일반적으로 yocto 에서는 root 유저는 빌드할 수 없다. (sanity.conf 에서 수정할
수는 있지만 기본값대로 진행하기 위해 사용자를 별도로 생성하였다.) 이를 위해
builduser 를 아래와 같이 생성해주자.

``` bash
$ useradd builduser
$ mkdir -p /home/builduser && chown -R builduser:builduser /home/builduser
$ su - builduser
```

# 마무리

이제 빌드를 위한 환경 구성은 마무리 되었다. Yocto 빌드도 컴파일 에러 없이
정상적으로 빌드 되는 것을 확인할 수 있을 것이다. 빌드가 마무리 되고 환경을
정리하려면 앞서 마운트했던 디렉토리들을 그대로 unmount 해주면 된다.

업무에 관련된 오픈 소스에 참여해볼 수 있는 좋은 기회를 찾은 것 같아 기쁘다.
무엇보다도 지난 2년 반 동안 항상 궁금해했던 질문들, 가령 "다른 곳에서는 어떤
개발 프로세스로 릴리즈를 할까?", "어떻게 모듈별로 관리하여 Yocto로 통합할까?",
"테스팅은 어떻게 할까?", "아키텍처에 관련된 커널 코드는 어떻게 테스팅을 할까?"
등에 대한 답을 찾을 수 있을 것 같다는 기대감이 크다.
