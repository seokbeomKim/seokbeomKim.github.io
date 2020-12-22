---
title: "WSL 가상 디스크 파일 D 드라이브에 옮기기"
date: 2020-12-23T23:00:00+09:00
categories: [O/S,Embedded]
tags: [WSL, vmmem]
---


WSL 을 사용하다 보면 디스크 용량이 커져 C 드라이브의 용량이 부족해진다. 용량이 넉넉하면 문제가 없겠지만 필자와 같이 C 드라이브는 O/S만 설치하고 D 드라이브에 다른 것들을 모두 설치하도록 환경을 설정한 경우에는 이러한 저장 방식은 꽤 부담스러워진다. 예전에는 이러한 문제에 대해 해결 방법이 따로 없었던 것으로 알고 있었는데 찾아보니 `lxrunoffline`이라는 툴로 간단하게 해결할 수 있었다.

윈도우즈 패키지 매니저인 `choco` 를 이용하여 `lxrunoffline`을 설치하고 이를 이용하여 WSL에 사용되는 가상 디스크 파일을 다른 드라이브로 옮길 수 있다.


``` powershell
> choco install lxrunoffline
> lxrunoffline move -n Ubuntu -d D:\wsl\
```