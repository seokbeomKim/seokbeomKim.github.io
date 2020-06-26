---
title: "mu4e 설정하기"
date: 2020-06-26T01:36:36+09:00
categories:
- emacs
tags:
- mu4e
keywords:
- tech
toc: false
---

# 개요

이맥스에서 사용할 수 있는 이메일 클라이언트로서 `mu4e`라는 것이
있다. 메일을 수신하여 분류, 저장하는데 목적이 있는 것이 아니라 메일을
인덱싱하여 빠르게 검색하고 org mode를 함께 사용하여 필요한 내용을
간단하게 메일 형태로 만들어낼 수 있는 것이 장점이다.

단점은 환경 설정하는 것이 단점인데 mu4e를 단독으로 사용할 수 없을
뿐더러 메일 클라이언트로서 일반 사용자가 사용하기에는 무리가 있다.

`mu4e`를 설정하는 방법은 온라인에서 쉽게 찾을 수 없다. 대신, 공식
문서와 몇몇 블로그 포스팅을 통해 관련 내용들을 찾을 수 있다.

- https://rakhim.org/fastmail-setup-with-emacs-mu4e-and-mbsync-on-macos/
- http://pragmaticemacs.com/mu4e-tutorials/

mu4e를 설정하는 순서는 대략 아래와 같다.


1. `isync` 패키지를 설치하고 `mbsync`를 설정하여 로컬에 동기화하고자
하는 메일 계정들을 설정한다.

2. `mu4e`를 사용하기 위해 이맥스를 설정한다.

## isync 설치하기
`mbsync` 명령어는 `isync` 패키지 안에 포함된다. 아치리눅스 위키
페이지에 패키지에 대한 설명이 자세히 기술되어 있다. 설치 후에는 아래
링크 또는 포스팅에 있는 예제 파일들을 참고하여 설정 파일을 작성한다.

- https://wiki.archlinux.org/index.php/Isync

```
# GMAIL #1
IMAPAccount sukbeom.kim
Host imap.gmail.com
User sukbeom.kim@gmail.com
PassCmd "gpg --batch --passphrase mu4e --no-tty -qd ~/.sbk.gpg"
AuthMechs LOGIN
SSLType IMAPS
SSLVersions SSLv3
CertificateFile /etc/ssl/certs/ca-bundle.crt

IMAPStore gmail-remote
Account sukbeom.kim

MaildirStore gmail-local
Path ~/mbsync/sukbeom.kim@gmail.com/
Inbox ~/mbsync/sukbeom.kim@gmail.com/INBOX

Channel gmail-inbox
Master :gmail-remote:
Slave :gmail-local:
Patterns "INBOX"
Create Both
Expunge Both
SyncState *

Channel gmail-trash
Master :gmail-remote:"[Gmail]/Bin"
Slave :gmail-local:"[Gmail].Bin"
Create Both
Expunge Both
SyncState *

Channel gmail-sent
Master :gmail-remote:"[Gmail]/Sent Mail"
Slave :gmail-local:"[Gmail].Sent Mail"
Create Both
Expunge Both
SyncState *

Channel gmail-all
Master :gmail-remote:"[Gmail]/All Mail"
Slave :gmail-local:"[Gmail].All Mail"
Create Both
Expunge Both
SyncState *

Channel gmail-starred
Master :gmail-remote:"[Gmail]/Starred"
Slave :gmail-local:"[Gmail].Starred"
Create Both
Expunge Both
SyncState *

Group gmail
Channel gmail-inbox
Channel gmail-sent
Channel gmail-trash
Channel gmail-all
Channel gmail-starred


IMAPAccount chaoxifer
Host imap.gmail.com
User chaoxifer@gmail.com
PassCmd "gpg --batch --passphrase mu4e --no-tty -qd ~/.chaoxifer.gpg"
AuthMechs LOGIN
SSLType IMAPS
SSLVersions SSLv3
CertificateFile /etc/ssl/certs/ca-bundle.crt

IMAPStore chaoxifer-remote
Account chaoxifer

MaildirStore chaoxifer-local
Path ~/mbsync/chaoxifer@gmail.com/
Inbox ~/mbsync/chaoxifer@gmail.com/INBOX

Channel chaoxifer-inbox
Master :chaoxifer-remote:
Slave :chaoxifer-local:
Patterns "INBOX"
Create Both
Expunge Both
SyncState *

Channel chaoxifer-trash
Master :chaoxifer-remote:"[Gmail]/Bin"
Slave :chaoxifer-local:"[Gmail].Bin"
Create Both
Expunge Both
SyncState *

Channel chaoxifer-sent
Master :chaoxifer-remote:"[Gmail]/Sent Mail"
Slave :chaoxifer-local:"[Gmail].Sent Mail"
Create Both
Expunge Both
SyncState *

Channel chaoxifer-all
Master :chaoxifer-remote:"[Gmail]/All Mail"
Slave :chaoxifer-local:"[Gmail].All Mail"
Create Both
Expunge Both
SyncState *

Channel chaoxifer-starred
Master :chaoxifer-remote:"[Gmail]/Starred"
Slave :chaoxifer-local:"[Gmail].Starred"
Create Both
Expunge Both
SyncState *

Group chaoxifer
Channel chaoxifer-inbox
Channel chaoxifer-sent
Channel chaoxifer-trash
Channel chaoxifer-all
Channel chaoxifer-starred
```

설정에서 gpg를 이용하여 계정 암호를 설정파일에 그대로 넣지 않고
암호화한 파일을 사용하도록 한다. gpg 파일을 만드는 방법은 아래와 같다.

```
$ echo "mypassword!" > ~/.mbsyncpass
$ gpg --output ~/.emacs.d/personal/chaoxifer.gpg --symmetric ~/.mbsyncpass
$ # 입력 창에 passphrase 를 입력한다. 위 설정에서는 mu4e를 passphase로 입력했다.
```

이제 mbsync를 사용하기 위한 설정이 완료되었다. 필요한 디렉토리들을
만들고 `mbsync init`, `mbsync -a`를 통해 메일 박스를 동기화한다.

## mu 설치
`mu4e` 사용을 위해, `mu` 패키지를 설치한다. 이 때 컴파일 옵션으로
이맥스 옵션이 있으니 확인하자. 기본적으로 이맥스 옵션이 활성화되어
패키지가 설치되므로 특별한 경우가 아니라면 별도로 설정하지 않아도
된다.

## 이맥스 설정
이제 마지막으로, 아래와 같이 mu4e를 로드한다. mu4e에 대한 추가 설정은
mu4e의 공식 문서에 자세히 기술되어 있다.

```
(if (eq running-env "private")
(if (eq system-type 'darwin)
(add-to-list 'load-path "/usr/local/Cellar/mu/HEAD-281a4cc/share/emacs/site-lisp/mu/mu4e/"))

(require 'mu4e)
(require 'mu4e-contrib)
(require 'gnutls)

(setq mu4e-sent-folder "/sent"	;; folder for sent messages
mu4e-drafts-folder "/drafts"	;; unfinished messages
mu4e-trash-folder "/trash"	;; trashed messages
mu4e-refile-folder "/archive"	;; saved messages
user-mail-address "메일 주소"
smtpmail-default-smtp-server "smtp.gmail.com"
smtpmail-smtp-server "smtp.gmail.com"
smtpmail-smtp-service 587)

(setq mu4e-index-cleanup nil	      ;; don't do a full cleanup check
mu4e-index-lazy-check t)      ;; don't consider up-to-date dirs


(setq mu4e-maildir "~/mbsync/"
mu4e-attachment-dir "~/mbsync/attachments"
user-full-name "Sukbeom Kim")

(setq mu4e-get-mail-command "mbsync -a"
mu4e-change-filenames-when-moving t
mu4e-view-show-images t
mu4e-view-show-addresses t
mu4e-update-interval (* 20 60))

(setq mu4e-html2text-command 'mu4e-shr2text
shr-color-visible-luminance-min 80
shr-color-visible-distance-min 5))

```

# 마무리
이제 필요한 설정이 모두 마무리 되었다. `M-x mu4e`를 통해 수신한
메일들을 관리하거나 지정되어 있는 smtp 서버를 통해 메일을 주고받을 수
있다. `mu4e`는 `thunderbird`의 마크다운 지원하는 메일 작성의 개념과
비슷하지만 모드를 자유자재로 선택할 수 있다는 점에서 더 유연하다는
장점이 있다. 또한 snippet 과 코드를 직접 메일에 붙일 수 있기에 메일
송수신 시에 매우 유용하다.
