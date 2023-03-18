---
title: "Device Tree Overlay"
date: 2022-05-08T01:37:45+09:00
categories:
- Computer Science
tags:
- device tree
- overlay
- kernel
---

## Ramoops 덕분에 알게된 오버레이

며칠전 리눅스에서의 Tracing 방법에 대해 공부하다가 찾아낸 세미나 영상에서 ramoops 라는 것을 알게 되었다.
ramoops는 커널이 oops/panic 이 발생하면서 warm reset 되었을 경우 재부팅 이후에 pstore (persistent store)을 이용하여 이전에 기록된 dmesg 나
user 콘솔의 기록을 확인할 수 있도록 하는 logger 이다. ramoops 는 cold reset 이 되면 기록이 남아있지 않는다는 단점이 있어
최근에는 ramoops 대신 blk oops/panic logger 를 사용하기도 한다.

이러한 로거를 현업에서 사용하기 위해 사내 평가보드에서 먼저 확인해보았다. 평가보드에서는 간단하게 memblock의 reserved memory 영역에 ramoops 영역을 추가함으로써 정상 동작하는 것을 금방 확인할 수 있었다. 하지만, 개인적으로 갖고 있던 라즈베리파이 보드에서는 이같은 방법이 제대로 동작하지 않았다.  이에 구글링을 하던 도중 디바이스 트리 오버레이로 ramoops 에 대한 디바이스 트리를 수정하는 방법을 접하면서, 오버레이가 특정 벤더의 BSP에서만 사용 가능한 것이 아닌 OF의 API로서 커널 내에 구현되어 있다는 사실 또한 함께 알게 되었다. (부끄럽게도 이제서야 알게 되었다.)

## 오버레이 작성

오버레이는 런타임에 FDT (Flattened Device Tree) 를 수정할 수 있는 방법이다. 여기서 FDT란, 메모리에 로드된 디바이스 트리를 말한다.
DTC (Device Tree Compiler) 버전에 따라 syntax 가 조금씩 달라지지만, 이전 방법으로는 아래와 같이 작성할 수 있다.

```text
/dts-v1/;
/plugin/;

/ {
        compatible = "brcm,bcm2835";

        fragment@0 {
                target = <&rmem>;
                __overlay__ {
                        #address-cells= <1>;
                        #size-cells = <1>;
                        ranges;

                        ramoops: ramoops@39000000{
                                compatible = "ramoops";
                                reg = <0x39000000 0x100000>;
                                ecc-size = <16>;
                                record-size = <0x20000>;
                                console-size = <0x20000>;
                                pmsg-size = <0x20000>;
                                ftrace-size = <0>;
                        };
                };
        };
};
```

그리고 이를 아래와 같이 컴파일한다.
```sh
$ dtc -@ -O dtb -o ramoops.dtbo ramoops-overlay.dts
```

## configfs

앞서 컴파일한 오버레이를 사용하기 위해서는 디바이스 트리를 사용했던 것과 마찬가지로 특정 메모리 영역에 dtbo 파일을 두고 오버레이 인터페이스를 통해 접근해야 한다.
하지만 overlay에 관련된 API 를 직접 호출할 필요 없이도 configfs 를 통해 쉽게 오버레이를 추가하거나 제거할 수 있다. 커널에서는 아래와 같이 DT overlay interface 로서 CONFIGFS 를 제공한다.

```text
CONFIG_OF_CONFIGFS:

Enable a simple user-space driven DT overlay interface.

Symbol: OF_CONFIGFS [=y]
Type  : bool
Defined at drivers/of/Kconfig:97
  Prompt: Device Tree Overlay ConfigFS interface
  Depends on: OF [=y]
  Location:
    -> Device Drivers
      -> Device Tree and Open Firmware support (OF [=y])
Selects: CONFIGFS_FS [=y] && OF_OVERLAY [=y]
```

만약 이 커널 옵션이 정상적으로 활성화되어 빌드되었다면 아래와 같이 `/sys/kernel/configs` 경로에 configfs 파일시스템이 마운트 되어 있는 것을 확인할 수 있다.

```bash
$ mount | grep -i config
configfs on /sys/kernel/config type configfs (rw,nosuid,nodev,noexec,relatime)
```

먼저, 파일시스템을 탐색해보면 아무것도 없다. `/sys/kernel/config/device-tree/overlay/` 까지의 디렉토리만 생성되어 있을 뿐 아무런 파일도 존재하지 않는다. 이 때, 임시로 디렉토리 하나를 만들어주면 아래와 같이 파일 여러개가 생성되어 있는 것을 알 수 있다. 그리고 해당 파일들의 내용을 보면 비어 있다.

```bash
$ mkdir /sys/kernel/config/device-tree/overlays/test
$ ls /sys/kernel/config/device-tree/overlays/test
dtbo  path  status
$ grep "" /sys/kernel/config/device-tree/overlays/test/*
/sys/kernel/config/device-tree/overlays/test/path:
/sys/kernel/config/device-tree/overlays/test/status:unapplied
```

이제, 앞서 컴파일 해놓은 dtbo 파일을 해당 파일시스템을 통해 로드해보자. 앞서 생성한 ramoops 노드가 동적으로 런타임에 추가된 것을 볼 수 있다(!!)

``` sh
$ cat ramoops.dtbo > /sys/kernel/config/device-tree/overlays/test/dtbo
$ ls /proc/device-tree/reserved-memory/ -al
total 0
drwxr-xr-x  5 root root  0 Apr 26 04:39  .
drwxr-xr-x 25 root root  0 Jul 21  2021  ..
-r--r--r--  1 root root  4 Apr 26 04:51 '#address-cells'
drwxr-xr-x  2 root root  0 Apr 26 04:51  linux,cma
-r--r--r--  1 root root 16 Apr 26 04:51  name
-r--r--r--  1 root root  4 Apr 26 04:51  phandle
drwxr-xr-x  2 root root  0 Apr 26 10:46  ramoops@39000000
-r--r--r--  1 root root  0 Apr 26 10:46  ranges
-r--r--r--  1 root root  4 Apr 26 04:51 '#size-cells'

$ grep "" /sys/kernel/config/device-tree/overlays/test/*
Binary file /sys/kernel/config/device-tree/overlays/test/dtbo matches
/sys/kernel/config/device-tree/overlays/test/path:
/sys/kernel/config/device-tree/overlays/test/status:applied
```

이렇게 오버레이를 통해 노드를 로드한 뒤에는 드라이버도 함께 신경써줘야 한다. 만약 관련된 드라이버가 built-in 되어 컴파일된 경우라면 자동으로 로드되지만 모듈로 빌드된 경우에는 반드시 modprobe 명령어로 로드해줘야 한다. 더이상 필요하지 않은 경우에는 아래와 같이 단순하게 디렉토리를 삭제해주면 된다.

```bash
$ rmdir /sys/kernel/config/device-tree/overlays/test/
```

## 언제 사용할까?

오버레이를 통해 런타임에 동적으로 FDT 의 내용을 변경할 수 있다는 점은 충분히 매력적이다. 어째서 라즈베리파이에서 상당 부분의 모듈들을 오버레이를 통해 제공하고 있는지도 함께 이해할 수 있었다. 현재 현업에서는 오버레이는 적용되지 않은채 디바이스 트리의 상속을 통해서 구조화 시킨채 FDT는 고정적으로 사용하고 있다. 만약 시나리오에 따라 디바이스 트리가 변경되도록 BSP를 개발해야 하는 때가 온거나 현재 커널 내에 구현된 유닛테스트와 같이 고정된 테스트 코드에 동적인 설정값들을 사용해야 한다면 오버레이가 그 해답이 될 수 있을 것이라 생각한다.

## 참고 자료

- [Android Device Tree Overlay](https://source.android.com/devices/architecture/dto)
- [dtbocfg](https://github.com/ikwzm/dtbocfg)
- [Dynamically Loading Device Tree Overlay](https://www.96boards.org/documentation/consumer/dragonboard/dragonboard410c/guides/dt-overlays.md.html#32-loading-overlays-via-configfs)