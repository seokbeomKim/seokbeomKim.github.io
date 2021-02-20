---
title: "Mac에서 GDB 이용한 커널 해킹하기"
date: 2021-02-20T02:43:54+09:00
draft: false
categories: gdb
tags:
- gdb
- mac_os

---

## 개요

맥에서도 GDB 를 이용하여 커널 디버깅을 하려고 여러 방법을 시도해보았지만 쉽게
되지 않았다. 리눅스 커널 컴파일부터 qemu 실행, gdb attach 까지 단번에 되는게
하나도 없었다. 특히 homebrew 를 통해 설치하는 gdb가 말썽이었는데, `aarch64`
아키텍처로 빌드된 바이너리로부터 심볼 테이블을 읽지 못했다. 대체 Dave 는
누구인가?

``` c++
(gdb) file ~/Workspaces/kernel_dev/vmlinux
Reading symbols from ~/Workspaces/kernel_dev/vmlinux...
I'm sorry, Dave, I can't do that.  Symbol format `elf64-littleaarch64' unknown.
```

이에 해결을 위한 시나리오는 아래와 같이 구성했다.

1. 컴파일 서버 구성: 개인적으로 사용하고 있는 게이밍 노트북 Hyper-V 로 리눅스
   Guest OS를 올려 컴파일 서버로 만든다.

2. sftp를 통해 컴파일 서버에서 빌드한 lisa-qemu 부트 이미지와 vmlinux 파일을
   받아 맥 os에서 qemu로 VM을 실행한다.

3. gdb 클라이언트로 gdb server에 접속하여 디버깅을 한다.

## Guest OS 및 포트포워딩, ssh 서버 설정

Guest OS는 lisa-qemu 설치를 위해서 우분투를 사용하였다. 우분투 설치 후 아래와
갈이 스위치 설정을 해준다.

``` powershell
New-VMSwitch -SwitchName "KeyNATSwitch" -SwitchType Internal
New-NetIPAddress -IPAddress 10.0.2.1 -PrefixLength 24-InterfaceAlias "vEthernet (KeyNATSwitch)"
```

그리고 hyper-v guest 설정 - 네트워크 어댑터 - 가상 스위치 설정에서
KeyNATSwitch를 선택해준다.

이제 우분투로 돌아가 스위치에 물리기 위한 netplan을 아래와 같이 설정한다.

``` shell
     network:
       version: 2
       renderer: NetworkManager
       ethernets:
         eth0:
           dhcp4: no
           addresses:
           - 10.0.2.4/8
           gateway4: 10.0.2.1
           nameservers:
             addresses: [8.8.8.8, 8.8.4.4]
```

설정 후에 `sudo netplan apply` 로 설정을 적용한다. 이제 마지막으로 포트포워딩을
설정해준다. External Port 는 아래와 같이 동일하게 해도 되나, 귀찮게 구는
중국으로부터의 트래픽을 피하고 싶다면 반드시 다른 포트로 설정해주자.

``` shell
New-NetNAT -Name "NATNetwork" -InternalIPInterfaceAddressPrefix 10.0.2.0/24
     Add-NetNatStaticMapping -ExternalIPAddress "0.0.0.0/24"
     -ExternalPort 22 -Protocol TCP -InternalIPAddress "10.0.2.4"
     -InternalPort 22 -NatName KeyNATNetwork
```

이제 컴파일러 서버가 준비되었으니 lisa-qemu를 설치하고 커널 부트 이미지를
준비한다. 이 부분은 이미 lisa-qemu 에 쉽게 가이드가 있으므로 생략한다.

## aarch64 target 용 gdb 빌드

먼저, gdb-10.1(https://ftp.gnu.org/gnu/gdb/gdb-10.1.tar.xz)을 받은 뒤 압축을
풀고, 맥에서 빌드시 문제가 되는 부분을 아래와 같이 수정해주자.


``` bash
$ vi bfd/elf-bfd.h

#define _LIBELF_H_ 1
+#include <string.h>
```

`<string.h>` 헤더파일을 추가해준 뒤, target만 지정해주고 컴파일해준다. 그리고
마지막으로 빌드된 gdb 바이너리를 bin 디렉토리에 복사해준다.

``` bash
$ /configure --disable-debug --disable-dependency-tracking --without-python --target=aarch64-linux-gnu --prefix=$HOME/xtools

$ make && make install
$ cp $gdb-10.1/gdb/gdb $HOME/xtools/bin
```

이제 모든게 준비가 되었다. lisa-qemu 를 디버깅 옵션으로 실행해주고 gdb 를
붙여주면 아래와 같이 맥에서도 디버깅이 가능해진다. 거기에 컴파일 서버까지 생긴건
덤이다.

![kernel-hacking-on-mac-os](/img/kernel-hacking-on-mac.png)
