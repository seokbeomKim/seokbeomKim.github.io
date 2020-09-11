---
title: "하스켈 버전 관리"
date: 2020-09-12T00:05:37+09:00
categories:
- haskell
tags:
- ghcup
---

# 개요

IDE 환경을 구성하기 위해 `haskell-ide-engine`을 설치하였지만 한 가지
문제가 발생하였다. 현재 기준 8.8.3 까지 지원하고 있는 ide-engine
버전이 8.10 까지 버전업 되어 있는 ghc 환경과 호환이 안되는 문제가
발생하였다. 이를 위해 하스켈의 전체적인 버전 관리를 해주는 패키지
매니저가 있을 것이라 생각하고 관련 내용으로 검색해보니 `ghcup` 이라는
버전 관리 매니저가 있었다.

ghcup은 아치리눅스의 경우 `AUR`에서 `ghcup-hs-bin` 패키지로 설치할 수
있으며 아래와 같이 원하는 ghc 버전들을 간편하게 설치하고 메인으로
관리할 수 있다. 단, `$HOME/.ghcup/bin` 경로에 설치되어 있으므로 셸
스크립트를 통해 환경변수로서 설정해줘야 한다.

# 참고 링크

* https://gitlab.haskell.org/haskell/ghcup-hs
