---
title: "Homebrew python 설치하기"
date: 2020-12-29T23:35:55+09:00
categories:
- python
tags:
- mac
- homebrew
---

Homebrew로 설치한 파이썬의 버전이나 경로가 기본 파이썬을 실행했을 때와
다를 경우 링크된 파일이 다른지 먼저 확인해야 한다. 이를 테면, pip
패키지 매니저로 확장 라이브러리를 설치해도 찾지 못하는
경우이다. 문제가 발생할 때 파이썬의 경로를 살펴보면,
`/usr/bin/python3' 등으로 /usr/bin 아래에 놓여있는 것을 알 수 있다.

이러한 경우, 아래와 같이 brew 명령어를 통해 다시 심볼릭 링크를
재정의해주자.

``` bash
brew link python@3.9
```
