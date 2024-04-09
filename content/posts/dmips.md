---
draft: true
title: "DMIPS (Dhrystone Million Instructions Per Second)"
date: 2020-04-03T01:41:29+09:00
categories:
- Computer Science
tags:
- dmips
- benchmark
---

## 개요

프로세서의 성능을 나타내는 지표로서 `DMIPS`라는 것을 사용하게 되었다. 벤치마크로 `MIPS`만 알고 있었는데 실제로 업무에서 사용했던 것은 `DMIPS`라는 것이어서 이번에 확실하게 정리하고 가고자 한다.

`DMIPS`는 드라이스톤(Dhrystone) 벤치마크 테스트의 결과를 정수화해서 이를 하중한 값으로 비교하는 방법으로 프로세서 성능 비교에 이용하는 지표이다. 예를 들어, ARM 32bit Cortex-M3 CPU - 72 MHz maximum frequency 모델의 경우 1.25 DMIS/MHz 인데 여기에 CPU 사용량을 이용하면 해당 프로세서가 가지는 Full DMIPS (72MHz 일 때의 DMIPS) 대비 측정하고자 하는 프로세스에 대한 DMIPS 지표를 얻을 수 있다.

예를 들어, A 프로세스의 평균 CPU 사용량이 10% 라고 가정하면, 위의 Cortex-M3 의 Full DMIPS는 72 * 1.25 = 90 DMIPS 이고, DMIPS * 0.1 = 9 DMIPS 라는 값을 산출해낼 수 있다.

## 링크

- <http://blog.daum.net/trts1004/12109217>
