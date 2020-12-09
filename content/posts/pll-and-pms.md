---
title: "PLL (Phase Locked Loop)"
date: 2020-12-08T15:04:30Z
categories:
- Embedded
tags:
- PLL
---

## 개요

업무 상에서 클럭 소스를 컨트롤 하기 위해 사용되는 것이 바로 PLL (Phase Locked Loop) 이다. 회로를 통해서 일정한 주파수를 생섬해주는 역할을 한다. 현업에서는 PLL 설정을 위한 값으로 PMS 를 사용하지만 출처에 따르면 M/N 이라는 기호로 나타낸 것을 알 수 있다.

## PLL 회로 사용 예

아래 회로는 10 MHz 클럭 소스를 이용하여 100 MHz Fout 을 만들어내는 PLL 회로이다.

![기본 PLL 회로](/img/MNPLL1.gif)

TCXO 는 심장과 같이 10 MHz 짜리 클럭 소스로 PLL 에 넣어준다. 그러면 VCO (Voltage Controlled Oscilator)가 원하는 주파수를 전압을 통해 만들어낸다. 이 때, VCO가 만든 주파수가 정상인지를 재확인하기 위해 1/N Divider로 샘블링해서 TCXO와 같은 레벨로 낮춘 후 100 MHz가 괜찮게 나오는지 TCXO와 다시 맞춰본다 (Phase Detector). 그리고 이러한 과정에서 100 MHz 가 아니라면 펄스 → 전압 변환기를 이용하여 VCO의 nput 전압을 재조정한다.

# M/N:d counter

이러한 PLL의 개념을 간단하게 나타내면 아래 회로로 나타낼 수 있다

![M/N:d counter](/img/MNPLL2.gif)

M 값이 1000 이라면 10 MHz 기준 1 GHz 가 되고 N이 10이면 1 MHz 가 된다. 이처럼 생성되는 주파수의 클럭수를 조정할 수 있는 이러한 회로를 PLL이라 부르며 M/N counter PLL이라 부른다.

그리고 이러한 PLL에 duty 개념을 추가한 것을 M/N:d counter라고 한다. Duty란 실제 High 구간과 Low 구간과의 비율을 나타낸 것으로 아래와 같이 구분할 수 있다

![Duty](/img/duty.jpg)
# PLL PMS

그렇다면, 현업에서 사용하는 PMS 값은 무엇일까? 위의 M/N PLL 회로에서 Post scaler 가 추가된 PLL 회로이다. 삼성의 데이터시트를 살펴보면 텔레칩스의 위키에서 언급된 내용이 잘 나와있는데, 해당 블럭 다이어그램을 살펴보면 아래와 같다.

![PLL PMS](/img/PLL_PMS.jpg)

M은 m, N은 p와 같으며, 이에 추가로 Post Scaler (s) 가 추가되어 있는 형태이다.# PLL (Phase Locked Loop)
