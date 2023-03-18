---
title: "커널 모듈과 드라이버의 차이"
date: 2019-05-16T02:11:40+09:00
categories:
- Kernel
tags:
- modules
- drivers
keywords:
- tech
---

오랜만에 커널 공부를 다시 시작하면서 소스 트리를 다시 살펴보게
되었다. 분명히 예전에도 같은 질문을 가졌겠거니 생각하면서 트리를 보고
난 후의 첫 질문을 정리하고자 한다.

커널 디렉토리 구조는 대략 다음과 같이 구성되며, 그 중 `drivers`와
`modules`의 차이점이 이해하기가 어려웠다.

``` text
arch/    - 특정 아키텍처에 국한된 코드
include/ - 커널 빌드를 위해 포함하는 include 파일들
init/    - 커널 초기화 코드
mm/      - 메모리 관리 코드
drivers/ - 드라이버
ipc/     - IPC (Inter Process Communication)
modules/ - 커널 모듈
fs/      - 파일시스템
kernel/  - 커널 코드
net/     - 네트워킹 코드
lib/     - 커널에서 사용하는 라이브러리
scripts/ - awk, tk와 같은 스크립트들(커널 configure 시에 사용)
```

구글링을 해보니 역시나 같은 생각을 한 사람이
있었다. [링크](https://unix.stackexchange.com/questions/47208/what-is-the-difference-between-kernel-drivers-and-kernel-modules)를
참고하면 커널 모듈은 윈도우즈의 DLL과 같이 커널 런타임에서 로드될 수
있는 컴파일된 코드로 설명되고 드라이버는 하드웨어를 운용하는 코드로
설명하고 있다. 단, 하드웨어 드라이버 중에서도 모듈 형태로 배포되는
것이 간혹 있기 때문에 모든 하드웨어 드라이버가 반드시 drivers
디렉토리에 포함되는 것처럼 설명할 수는 없다고 한다.
