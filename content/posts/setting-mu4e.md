---
title: "mu4e 설정하기"
date: 2020-06-26T01:36:36+09:00
categories:
- etc
tags:
- mu4e
keywords:
- tech
toc: true 
---
# 개요
이맥스에서는 이메일 클라이언트로서 사용할 수 있는 `mu4e`라는 패키지가 있다.
일반적으로 `isync (mbsync)` 라는 프로그램과 함께 사용하며 mu 를 설치하면 설치
디렉토리 내에 함께 포함되어 있다. `mu`는 메일 수신 및 분류, 저장 보다는 인덱싱과
검색을 위한 프로그램이기 때문에 원하는 메일을 빠르게 검색하고 org mode와 함께
사용하여 필요한 내용을 간단하게 메일 형태로 만들어낼 수 있는 것이 특징이다.

그런데 outlook 이나 mailbird, thunderbird 등의 메일 클라이언트가 존재하는데 굳이
mu 를 사용하는 이유가 있을까? 일반 사용자라면 `mu` 보다는 앞서 언급된 메일
클라이언트를 사용하는 것이 좋다. 하지만 리눅스 커널 프로젝트에 패치를 보내고
다른 사람들이 보낸 패치를 받아 적용하는 등의 작업이 필요하다면 일반적인
클라이언트보다는 `mu` 를 사용하는 것이 좋다. 이메일을 통해 패치 파일을 inline
형태로 보내야 하는데 첨부 형식을 보장하는 메일 클라이언트는 몇 개 남아있지 않다.
또한 일부 메일 클라이언트는 간단한 평문을 보내더라도 html 를 이용해 태그가 붙어
있는 경우도 있다.

> Patches for the Linux kernel are submitted via email, preferably as inline
text in the body of the email. Some maintainers accept attachments, but then the
attachments should have content-type text/plain. However, attachments are
generally frowned upon because it makes quoting portions of the patch more
difficult in the patch review process.

mu4e를 설정하는 방법은 공식 문서와 몇몇 블로그 포스팅을 통해 관련 내용들을 찾을
수 있다.

- https://rakhim.org/fastmail-setup-with-emacs-mu4e-and-mbsync-on-macos/
- http://pragmaticemacs.com/mu4e-tutorials/ 

# 환경 구성
mu4e를 구성 & 설정하는 순서는 대략 아래와 같다.

1. mbsync (isync 패키지 내에 포함된 메일 fetcher) 설정 및 local inbox 생성
2. mu 인덱싱 구성
3. mu4e 사용하기 위한 이맥스 설정

## isync 설치

mbsync 명령어는 isync 패키지 안에 포함된다. 우분투 기준으로 아래와 같이 공식
repo 를 통해 설치 가능하다.

```bash
$ sudo apt install isync
```

## isync 설정

아치리눅스 위키 페이지에 패키지에 대한 설명이 자세히 기술되어 있다. 설치 후에는
아래 링크 또는 포스팅에 있는 예제 파일들을 참고하여 설정 파일을 작성한다.

- https://wiki.archlinux.org/index.php/Isync

```
# GMAIL #1
IMAPAccount sukbeom.kim
Host imap.gmail.com
User sukbeom.kim@gmail.com
PassCmd "gpg --batch --passphrase mu4e --no-tty -qd ~/.sbk.gpg"
AuthMechs LOGIN
SSLType IMAPS
SSLVersions TLSv1.3
CertificateFile /etc/ssl/certs/ca-certificates.crt

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

설정에서 gpg를 이용하여 계정 암호를 설정파일에 그대로 넣지 않고 암호화한 파일을
사용하도록 한다. gpg 파일을 만드는 방법은 아래와 같다.

```bash
$ echo "mypassword!" > ~/.mbsyncpass

# 입력 창에 passphrase 를 입력한다. 위 설정에서는 mu4e를 passphase로 입력했다.
$ gpg --output ~/.emacs.d/personal/chaoxifer.gpg --symmetric ~/.mbsyncpass
```

이제 mbsync를 사용하기 위한 설정이 완료되었다. 필요한 디렉토리들을 생성 후
mbsync -a를 통해 메일 박스를 동기화한다.

```bash
$ mkdir -p $HOME/mbsync/{chaoxifer@gmail.com,sukbeom.kim@gmail.com}
$ mbsync -a
```

## mu 설치

mu4e 사용을 위해, mu 패키지를 설치한다. 이 때 컴파일 옵션으로 이맥스 옵션이
있으니 확인하자. 기본적으로 이맥스 옵션이 활성화되어 패키지가 설치되므로 특별한
경우가 아니라면 별도로 설정하지 않아도 된다. mu 는 공식 repo 대신
https://github.com/djcb/mu/releases/tag/v1.8.14 에서 직접 받아서 설치하였다.
우분투의 공식 repo 에서 제공하는 버전과 꽤 차이가 나고 몇몇 버그 패치가 되지
않았기 때문에 직접 받아서 설치하는 것을 권장한다.

```bash
$ tar xf mu-1.8.14.tar.xz
$ cd mu-1.8.14
$ ./autogen.sh --prefix=$HOME/opt
$ make && make install
```

필자는 로컬 유저에서 받아서 설치하는 것은 모두 $HOME/opt 경로로 설치하는
타입이라 위와 같이 configure 을 진행하였다. 설치하고 난 뒤 디렉토리에 가보면
아래와 같이 mu4e 가 설치되어 있는 것을 볼 수 있다.

```bash
sukbeom@LAPTOP-R4FQS2C5:~$ ls opt/share/emacs/site-lisp/mu4e/
mu4e-actions.el     mu4e-context.el   mu4e-headers.elc    mu4e-mark.el      mu4e-server.elc    mu4e.el
mu4e-actions.elc    mu4e-context.elc  mu4e-helpers.el     mu4e-mark.elc     mu4e-speedbar.el   mu4e.elc
mu4e-bookmarks.el   mu4e-contrib.el   mu4e-helpers.elc    mu4e-message.el   mu4e-speedbar.elc  org-mu4e.el
mu4e-bookmarks.elc  mu4e-contrib.elc  mu4e-icalendar.el   mu4e-message.elc  mu4e-update.el     org-mu4e.elc
mu4e-compose.el     mu4e-draft.el     mu4e-icalendar.elc  mu4e-org.el       mu4e-update.elc
mu4e-compose.elc    mu4e-draft.elc    mu4e-lists.el       mu4e-org.elc      mu4e-vars.el
mu4e-config.el      mu4e-folders.el   mu4e-lists.elc      mu4e-search.el    mu4e-vars.elc
mu4e-contacts.el    mu4e-folders.elc  mu4e-main.el        mu4e-search.elc   mu4e-view.el
mu4e-contacts.elc   mu4e-headers.el   mu4e-main.elc       mu4e-server.el    mu4e-view.elc
```

## mu 설정

이제 mbsync 로 생성해놓았던 디렉토리를 기준으로 초기화한다.

```bash
$ mu init --maildir=$HOME/mbsync
$ mu info
+-------------------+--------------------------------+
| maildir           | /home/sukbeom/mbsync           |
+-------------------+--------------------------------+
| database-path     | /home/sukbeom/.cache/mu/xapian |
+-------------------+--------------------------------+
| schema-version    | 465                            |
+-------------------+--------------------------------+
| max-message-size  | 100000000                      |
+-------------------+--------------------------------+
| batch-size        | 250000                         |
+-------------------+--------------------------------+
| created           | Thu Mar 16 23:23:40 2023       |
+-------------------+--------------------------------+
| personal-address  |                                |
+-------------------+--------------------------------+
| messages in store | 38                             |
+-------------------+--------------------------------+
| last-change       | Sat Mar 18 07:09:36 2023       |
+-------------------+--------------------------------+
| last-index        | Sat Mar 18 07:09:32 2023       |
+-------------------+--------------------------------+
```

## 이맥스 설정

이제 마지막으로, 아래와 같이 mu4e를 로드한다. mu4e에 대한 추가 설정은 mu4e의
공식 문서에 자세히 기술되어 있다.

```elisp 
; 설치한 경로로 설정한다.
(add-load-path! "/home/sukbeom/opt/share/emacs/site-lisp/mu4e/")

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

# 마치며
이제 필요한 설정이 모두 마무리 되었다. M-x mu4e를 실행해 제대로 메일이 보이는지
확인한다.

mu4e 를 통해 이제 수신한 메일들을 관리하거나 지정되어 있는 smtp 서버를 통해
메일을 주고받을 수 있다. mu4e는 thunderbird의 마크다운 지원하는 메일 작성의
개념과 비슷하지만 모드를 자유자재로 선택할 수 있다는 점에서 더 유연하다는 장점이
있다. 또한 snippet 과 코드를 직접 메일에 붙일 수 있기에 메일 송수신 시에 매우
유용하다.

