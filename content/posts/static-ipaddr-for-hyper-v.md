---
title: "Hyper-V 가상 환경에서 고정 아이피 주소 사용하기"
date: 2020-03-01T17:12:34+09:00
categories:
- virtualization
tags:
- hyper-v
keywords:
- tech
toc: true
---

# 개요
윈도우즈에서 리눅스 환경을 이용하기 위해서는 docker 컨테이너를 이용하거나 hyper-v, vmware, virtualbox 등과 같은 가상머신을 이용해야 한다.
이번에는 hyper-v를 이용해 리눅스 환경을 구축하고 SSH를 통해 접속하여 필요한 작업을 하려 했는데 문제는 IP가 계속해서 동적으로 바뀌는 것이었다. 이를 해결하기 위해 네트워크 구성 방법과 간단한 가이드를 작성하고자 한다. 향후 Hyper-V 를 사용하면서 요구되는 시나리오가 추가되면 본 포스팅 문서를 수정하여 정리하도록 한다.

## 가상머신 클라이언트에 static ip 할당하기
가상머신에 고정 아이피를 할당하기 위해서는 가상 스위치 장치를 이용해야 한다. 가상 스위치의 패킷을 실제 네트워크 어댑터(이더넷 또는 와이파이)와 공유하도록 하고 가상 스위치의 아이피를 가상 머신에서 사용하는 게이트웨이로 지정하여 호스트에서 SSH로 접속할 수 있는 환경을 구성한다.

1. 작업 > 가상 스위치 관리자
현재 Default Switch로 되어 있는 스위치가 내부 네트워크로 되어 있는지 확인한다. '내부 네트워크'로 선택되어 있는 경우라면 가상 스위치를 추가할 필요가 없지만 만약 선택되어 있다면 이 단계는 넘어가자.

- 스위치가 없는 경우 '새 가상 네트워크 스위치'를 선택하여 내부 타입의 가상 스위치를 하나 생성한다.

2. 네트워크 설정
'제어판 - 네트워크 및 인터넷 - 네트워크 설정' 에서 내부 가상 스위치의 속성으로 들어가 고정아이피를 직접 할당한다. 아래는 직접 사용한 설정 정보이다.

``` 
IP: 192.168.137.1
subnet mask: 255.255.255.0
```

스위치에 대한 네트워크 설정을 마쳤으면 이더넷 또는 와이파이 어댑터의 속성에서 공유 탭의 '인터넷 연결 공유'에 '다른 네트워크 사용자가 이 컴퓨터의 인터넷 연결을 통해 연결할 수 있도록 허용' 옵션을 활성화해준다.

3. 가상머신에서 네트워크 설정
이제 거의 끝났다. 가상머신에서 직접 아래와 같이 네트워크 설정을 해준다. 위에서 설정한 스위치 아이피를 gateway로 설정하고 원하는 고정아이피로 설정하면 끝이다.

``` bash
$ ifconfig
eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.137.10  netmask 255.255.255.0  broadcast 192.168.137.255
        inet6 fe80::87d1:e5b6:b588:1e48  prefixlen 64  scopeid 0x20<link>
        ether 00:15:5d:99:75:00  txqueuelen 1000  (Ethernet)
        RX packets 30118  bytes 13541072 (13.5 MB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 19934  bytes 6482177 (6.4 MB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 44920  bytes 18330975 (18.3 MB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 44920  bytes 18330975 (18.3 MB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

$ ip route show
default via 192.168.137.1 dev eth0 proto static metric 100
169.254.0.0/16 dev eth0 scope link metric 1000
192.168.137.0/24 dev eth0 proto kernel scope link src 192.168.137.10 metric 100

```

이제 호스트 윈도우즈에서 클라이언트로 SSH를 통해 접속할 수 있는 고정아이피가 완성되었다.


# 출처
- https://medium.com/@maxtortime_88708/hyper-v-%EB%84%A4%ED%8A%B8%EC%9B%8C%ED%81%AC-%EC%84%A4%EC%A0%95%ED%95%98%EA%B8%B0-b459a7b0bd11