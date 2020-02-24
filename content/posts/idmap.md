---
title: "Identity Mapping"
date: 2020-02-24T23:01:54+09:00
categories:
- kernel
tags:
- idmap
---

ARM64 페이징을 공부하다보니 idmap (Identity Mapping)이라는 용어가 등장했다. 페이지 테이블이 완전하게 준비가 되지 않았을 때 임시로 사용하는 매핑 방법 중의 하나인데 오늘을 여기에 대해서 정리하고자 한다.

1. idmap이 무엇이고 왜 필요한가?
2. idmap 을 사용하는 코드는 어떤 것이 있는가?
3. ARM 리눅스 커널에서는 어떻게 활용하고 있는가?

# idmap (Identity Mapping)

가상주소와 물리주소가 매핑되는 방식 중의 한 가지다. 리눅스 커널에서 사용하는 주소 매핑 방식을 아래와 같이 3가지로 구분할 수 있다.

## linear 영역

`가상주소 + offset = 물리주소` 와 같이 주소 변환이 가능한 방식이다. ARM에서는 섹션에 매핑되는 커널 주소가 이 방식을 사용한다. 커널에서는 linear 영역에 대한 주소변환 함수로 `virt_to_phys`, `phys_to_virt`  등을 제공한다. 

## non-linear 영역

가상주소 → page table → 물리주소 등으로 페이지 테이블을 거쳐야만 변환이 가능한 주소 영역이다. 단순히 offset 계산만으로는 알 수 없는 경우이다. 일반적으로 페이지 매핑되는 모든 주소가 non-linear 영역이라고 보면 된다.

## idmap

MMU를 활성화하는 코드를 실행해야 한다고 가정했을 때, 가상주소가 곧바로 물리주소로 바로 사용된다. 즉, 페이지 테이블이 준비되지 않은 경우 가상주소와 물리주소를 1:1로 매핑하여 사용하는데 이러한 방식을 `idmap` 이라 한다.

# idmap 사용 예

리눅스 커널 코드 중에서 `arch/arm/` 하위에서 `.pushsection .idmap.text,"ax"` 등과 같은 문구가 나오는데 이러한 것들이 idmap 코드 영역에 포함되는 코드들이다.

- 최초 부팅 시 MMU 활성화 시: MMU 활성화 전까지는 주소 변환이 불가능하므로 당연히 idmap 되어야 한다.
- suspend-resume 에서 resume 직후 MMU를 활성화 할 때: arch/arm/kernel/sleep.S - cpu_resume_mmu()
- soft cpu reset 시: reset 수행 전 MMU를 비활성화
