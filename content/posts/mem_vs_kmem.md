---
title: "/dev/mem vs. /dev/kmem"
date: 2020-01-29T23:30:44+09:00
categories:
- Kernel
tags:
- mem
- kmem
keywords:
- tech
toc: false
---

# 개요
업무에서 사용하는 디버깅 툴은 특정 레지스터 정보를 보기 위해, 메모리 상에 매핑되어 있는 주소에 접근하여 해당 레지스터의 값을 읽어오는 방식을 이용한다. 이 때, /dev/mem 디바이스 노드가 반드시 있어야 한다고 들었기에 Kconfig에서 관련 설정 플래그를 찾던 중 kmem 이라는 것도 있다는 것을 알게 되었다. 문득 이 둘의 차이점과 공식적(?)인 디버깅 툴이 어떤 것이 있는지 알아보고자 한다.

# /dev/mem vs. /dev/kmem
이 둘의 차이점은 출처에 따르면 아래와 같이 나와있다.

> /dev/mem is a device file that directly represents physical memory, so an open(/dev/mem)/seek(1000)/read(10) system call combination ends up reading 10 bytes from RAM address 1000.

> /dev/kmem is a device file that directly represents kernel virtual memory, so an open(/dev/kmem)/seek(1000)/read(10) system call combination ends up reading 10 bytes from virtual address 1000, which is in turn mapped by your system's memory management unit to some physical RAM address.

쉽게 요약하면, /dev/mem : /dev/kmem = physical memory : virtual memory 의 관계인 것이다.

# 출처
- https://www.quora.com/What-is-the-difference-between-dev-mem-and-dev-kmem
- https://lwn.net/Articles/147901/