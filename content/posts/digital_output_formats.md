---
title: "영상 출력 포맷"
date: 2020-01-26T17:44:18+09:00
categories:
- Computer Science
tags:
- bt.601
- bt.656
---

# 디지널 출력 포맷

아날로그 신호에 대한 디지털 포맷으로서 표준화된 포맷들을 기술한다. 대표적인 표준으로는 BT.601, BT.656 이 있으며 그 외에도 최근에는 BT.2020 등의 고화질 영상을 타겟으로 한 표준들이 나오고 있다. 디지털 텔레비전의 부호화 파라미터들을 정의한 권고안으로서 601은 모든 컴포넌트 디지털 영상 표준에 대한 기초가 되었다.

## 규격 내용

각 표준에는 아래와 같은 내용들을 정의한다.

- 화면비
- 휘도 및 색 신호에 대한 처리
- 영상 포맷 형식
- 기준 주파수
- 샘플링 주파수
- 샘플링 및 코딩 형식

## BT.601

Rec. 601 또는 BT.601, CCIR 601로 알려져있는 표준으로서 컬러 인코딩 시스템은 YCbCr 4:2:2 를 따른다.

![BT.601](/img/bt601.png)

BT.601 의 경우 위 그림과 같이 HSYNC, VSYNC, DATA, PCLK 등의 필수 신호들로 통신하는 것을 알 수 있다.

## BT.656

위의 BT.601에서 HSYNC, VSYNC, DATA 선을 필요로 하는 것과 달리, BT.656에서는 DATA 라인에 타이밍 정보를 함께 포함해서 보내주는 것이 특징이다. 때문에 VSYNC, HSYNC 를 위해 필요한 핀을 절약할 수 있다는 장점이 있다.

![BT.656](/img/bt656.png)

## BT.709 & BT.2020

BT.709 는 방송용 출력 포맷(예. HDTV)으로 사용되며, 컬러 표현 영역이 작다는 것이 큰 단점이다. 이를 보완하기 위해 새로 나온 것이 BT.2020 이며, UHDTV를 위한 방송용 색 표현을 위한 표준이다. 업무에서 사용하는 SDTV 해상도와는 달리 컬러 색에 대한 표현 자체의 스펙이 다르기 때문에 특수한 카메라를 사용해야 한다. (카메라 예시: [https://www.adorama.com/cac500m2.html](https://www.adorama.com/cac500m2.html))

- [UHDTV 방송의 컬러 표현](https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&ved=2ahUKEwi82sLV7qDnAhXGy4sBHT_TBEUQFjAAegQIARAB&url=http%3A%2F%2Fwww.itfind.or.kr%2Fadmin%2FgetFile.htm%3Fidentifier%3D02-004-141031-000021&usg=AOvVaw0eD-3Mrqa0KjW7u0z-Wp7V)

# 출처

- [https://en.wikipedia.org/wiki/Rec._601](https://en.wikipedia.org/wiki/Rec._601)
