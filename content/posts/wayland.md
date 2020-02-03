---
title: "Wayland과 Weston"
date: 2020-02-03T23:17:11+09:00
categories:
- linux
tags:
- wayland
- weston
---

# 개요
직접적으로 연관된 업무는 아니지만 팀 내에서 `wayland`, `weston` 이라는
용어가 자주 들린다. 어렸을 적에 리눅스 데스크탑 환경에 관심이 많아
`X11` 기반으로 최소한의 작업 환경을 맞추고 `gnome`이나 `kde`, `xfce`가
아닌 `fluxbox`, `blackbox`, `i3`, `xmonad`, `enlightenment` 등을
이용해서 이런저런 시도를 해보았던 기억이 난다. 당시에는 그저 설치해서
사용하기에만 급급했지 실제로 업무에서 그러한 것들이 사용될 줄은 꿈에도
몰랐다.

이번 포스팅에서는 사내 위키의 내용을 출처로 하여, `wayland`, `weston`에
대한 구조를 살펴보고 클라이언트 예제를 기술하고자 한다.

