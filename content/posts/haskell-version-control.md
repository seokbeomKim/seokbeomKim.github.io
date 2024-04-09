---
draft: true
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
관리할 수 있다. 먼저, `ghcup list` 명령어를 통해 `ghc` 로 설치된
패키지들의 목록을 확인해보자.

``` bash
public git:6c65fe3 ❯ ghcup list
   Tool  Version      Tags                                 Notes
✗  ghc   7.10.3       base-4.8.2.0
✗  ghc   8.0.2        base-4.9.1.0
✗  ghc   8.2.2        base-4.10.1.0
✗  ghc   8.4.1        base-4.11.0.0
✗  ghc   8.4.2        base-4.11.1.0
✗  ghc   8.4.3        base-4.11.1.0
✗  ghc   8.4.4        base-4.11.1.0
✗  ghc   8.6.1        base-4.12.0.0
✗  ghc   8.6.2        base-4.12.0.0
✗  ghc   8.6.3        base-4.12.0.0
✗  ghc   8.6.4        base-4.12.0.0
✗  ghc   8.6.5        base-4.12.0.0
✗  ghc   8.8.1        base-4.13.0.0
✗  ghc   8.8.2        base-4.13.0.0
✔✔ ghc   8.8.3        base-4.13.0.0
✗  ghc   8.8.4        recommended,base-4.13.0.0
✗  ghc   8.10.1       base-4.14.0.0
✓  ghc   8.10.2       latest,base-4.14.1.0
✗  ghc   9.0.1-alpha1 prerelease,base-4.15.0.0
✗  cabal 2.4.1.0
✗  cabal 3.0.0.0
✗  cabal 3.2.0.0      latest,recommended
✗  cabal 3.4.0.0-rc2  prerelease
✔✔ ghcup 0.1.10       latest,recommended
```

현재 기본으로 설정되어 있는 `ghc` 버전과 `ghcup` 버전 등을 리스트로
확인할 수 있다. 새로 ghc 버전을 설치하기 위해서는 아래 명령어로 버전을
간편하게 설치할 수 있다.

``` bash
$ ghcup install ghc 8.8.2 # install ghc of version 8.8.2
$ ghcup set ghc 8.8.2     # set default version to 8.8.2
```

중요한 것은 `ghcup`을 통해 설치하는 모든 바이너리는 `$HOME/.ghcup/bin`
경로에 설치되어 있으므로 셸 스크립트를 통해 해당 경로를 참조할 수
있도록 `$PATH` 환경변수를 조정해줘야 한다.

# 참고 링크

* https://gitlab.haskell.org/haskell/ghcup-hs
