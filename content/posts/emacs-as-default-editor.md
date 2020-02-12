---
title: "이맥스 기본 에디터로 사용하기"
date: 2020-02-09T03:09:59Z
categories:
- linux
tags:
- emacs
---

# 개요
이맥스를 메인으로 사용하는 환경을 위해서 필요한 몇 가지 설정 값에 대해
포스팅하고자 한다. 이맥스의 경우 다른 vim 과 마찬가지로 초기 로드가
상당히 오래 걸리는 편이다. `daemon` 형태로 실행한다고 해도, 첫 로드를
위해 필요한 시간은 다른 편집기에 비해서 오래 걸리는 편이다. 때문에
편집기를 실행하고자 하는 때에 초기화를 진행하지 않고 사용자로
로그인하여 부트하는 시간에 편집기의 초기화를 진행하도록 설정할 것이다.

데몬 형태로 실행하는 것을 사용자 레벨의 `systemd`로 활성화함으로써
로그인 시에 자동으로 실행되게 한다. 그리고 `gnome`에서 사용하는 몇
가지 애플리케이션 설정만 바꿔주면 기본적인 파일들에 대한 편집은
이맥스에서 사용할 수 있게 된다.

## 설정 환경
본 포스팅 작성에 사용된 리눅스 환경은 아래와 같다.

- distro: Arch Linux
- D/E: Gnome 3.34.2
- systemd: 244.2-1

# systemd 에 emacs 등록하기
현재 대부분의 리눅스 배포판에서는 initrc 에서 systemd 로
바뀌었다. initrc를 고집하던 젠투에서도 `systemd`를 사용하는 것을 보면,
아마 대부분의 배포판에서 사용하고 있을 거라 생각하며, initrc를
사용하는 시스템이라면 젠투 쪽의 위키페이지를 참고하기를 바란다.

먼저 `~/.config/systemd/user/emacs.service` 파일을 아래와 같이
생성한다.

``` shell
[Unit]
Description=Emacs text editor
Documentation=info:emacs man:emacs(1) https://gnu.org/software/emacs/

[Service]
Type=forking
ExecStart=/usr/bin/emacs --daemon
ExecStop=/usr/bin/emacsclient --eval "(kill-emacs)"
Environment=SSH_AUTH_SOCK=%t/keyring/ssh
Restart=on-failure

[Install]
WantedBy=default.target
```

그 뒤, `systemctl` 명령어를 이용해 해당 서비스를 활성화한다.

``` shell
systemctl enable --user emacs
systemctl disable --user emacs
```

# gnome application 아이템 조정하기
gnome에서 파일을 열 때 `mime type`에 따라 기본으로 열기 위한
애플리케이션을 미리 정의해놓는다. 아래와 같이
`/usr/share/applications/emacs.desktop` 파일을 열어서 `emacsclient`를
이용하도록 설정한다.

``` shell
[Desktop Entry]
Name=Emacs
GenericName=Text Editor
Comment=Edit text
MimeType=text/english;text/plain;text/x-makefile;text/x-c++hdr;text/x-c++src;text/x-chdr;text/x-csrc;text/x-java;text/x-moc;text/x-pascal;text/x-tcl;text/x-tex;application/x-shellscript;text/x-c;text/x-c++;
Exec=emacsclient -c -a "" %F
Icon=emacs
Type=Application
Terminal=false
Categories=Development;TextEditor;
StartupWMClass=Emacs
Keywords=Text;Editor;
```

이제 모든 설정이 끝났다. 파일에 대한 기본 편집툴을 이맥스로 설정하면,
별도의 초기화 과정 없이 곧바로 실행되는 것을 알 수 있다.

# 출처
- https://www.emacswiki.org/emacs/EmacsAsDaemon
