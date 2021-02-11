---
title: "i3 window manager"
date: 2021-02-11T18:20:10+09:00
categories:
- Linux
- Window Manager
tags:
- i3wm
---

# 우분투 데스크탑 환경 삭제하기

개인적으로 우분투를 좋아하지 않지만, 맥북에 리눅스 환경을 구성하기 위해 필요한
서드파티 드라이버들이 우분투를 기반으로 배포되고 있어 이들을 손쉽게 설치 하기
위해 우분투를
설치하였다. (https://seokbeomkim.github.io/posts/linux-on-mbp/). 우분투를 설치한
뒤에 필요한 커널 코드 컴파일와 GDB, QEMU 연동 환경을 구성하자 램 부족으로
가상머신이 죽어버렸다. 겨우 이맥스와 gdb, firefox, qemu 만을 돌렸을 뿐인데
이렇게 힘들어하니 이해할 수가 없었다.

리소스 부족의 원인을 살펴보니 불필요한 서비스들이 너무 많이 돌고 있었다. 예를
들어, goa (gnome online accounts), snapd (snap package manager) 등 원하지도 않는
서비스들이 설치되어 리소스들을 좀먹고 있었다.

Desktop Environment 로서 제공되는 Gnome, Kde, Xfce, Lxde 등 다양한 "데스크탑
환경"들이 제공되지만, 어짜피 데스크탑 환경이지 반드시 설치할 필요는 없다. 아치
리눅스나 젠투 리눅스를 사용했다면 이를 처음부터 설치하지 않을 수 있었겠지만,
우분투이므로 그러려니 했다. ubuntu-desktop 및 패키지 중에서 gnome 응용
프로그램에 관련된 모든 것은 지워버리고 본래 사용하던 i3wm 만을 설치하여 작업
환경을 구성하였다.

Login manager 또한 필요가 없기에 gdm3, lightdm, xdm 등의 프로그램들은 모두
삭제하고 단순하게 터미널로 접속했을 때 자동으로 X 서버에 접속하도록 shell init
script를 수정하였다. 마지막으로 부팅 스플래시 로고를 위해 내 랩탑을 힘들게 하는
plymouth 도 함께 제거해주었다.

``` bash
# bash_profile 또는 zshrc에 아래 내용을 추가한다.
# 이 때 ~/.xsession에는 exec i3가 반드시 작성되어 있어야 한다.
if [[ ! ${DISPLAY} && ${XDG_VTNR} == 1 ]]; then
    exec startx
fi
```

# 윈도우 매니저 설치 후 리소스 사용량

그놈을 설치하여 부팅 후의 메모리 사용량은 대략 2GB 를 초과한다. 하지만 windows
manager (개인적으로는 xmonad, i3를 선호한다)만을 사용하여 간결하게 구성하면 부트
후에 700 ~ 800 MB 정도의 메모리 사용으로 충분하게 구성할 수 있다. 이렇게 차이가
많이 나니, 8GB 메모리를 가지고 있는 지금의 랩탑에서 그놈 환경이라면, 인터넷
브라우저만 실행해도 가용 메모리가 절반 가량으로 줄어든다. 대략 lisa-qemu 의
메모리 최소 요구사항이 4 GB 인 것을 감안하면 커널 분석 환경 자체가 정말
간당간당하게 돌아가고 디버깅을 하다보면 어쩔 수 없이 가상머신이 램 부족으로
죽어버린다.

# shared input method 와 i3wm 성능 문제

환경을 구성하다 보니 한 가지 이슈가 있었는데, ibus 의 현재 설정된 input method
을 다른 window와 공유하지 않게 설정할 경우 창 관리자의 성능이 급격하게 저하하는
이슈가 있다. 널리 퍼져 있는 내용은 아니지만, 아래 링크에서 관련된 내용을 참고할
수 있다. (https://github.com/i3/i3/issues/3924)

# Rofi (alternative to dmenu)

몇 년 전까지만 해도 dmenu 만을 알고 사용했었는데, rofi 라는 패키지가 있다는 것을
새로 알게됐다. 인터페이스도 dmenu 보다 훨씬 더 미려할 뿐만 아니라 설정 가능한
부분이 많아 dmenu 보다 유용했다. rofi 를 이용해서 디스플레이나 마운트 등을 할 수
있도록 간단하게 스크립트를 짜놓으니 아래와 같이 다양하게 활용할 수 있었다. bash
스크립트로 정말 간단하게 스크립트만 짜면 아래와 같이 현재 플러그인 되어 있는
장치들을 리스트하여 마운트 또는 언마운트 할 수 있다. 관련 스크립트는
https://github.com/seokbeomKim/ShellScriptRepo/tree/master/i3_stuff 에
올려놓았다.

![](/img/i3wm.gif)
