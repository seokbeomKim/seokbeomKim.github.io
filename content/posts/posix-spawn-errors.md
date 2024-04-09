---
draft: true
title: "command: posix_spawn failed: Resource temporarily unavailable"
date: 2019-06-23T10:46:29+09:00
categories:
- Etc
tags:
- posix-spawn
keywords:
- tech
---

QEMU를 맥에서 빌드하던 중 아래와 같은 에러가 출력되었다.

![](/img/posix-spawn.png)

이를 위한 해결 방법은 [링크](https://www.gowhich.com/blog/108)에서
쉽게 찾을 수 있었는데 한번에 실행할 수 있는 프로세스의 개수 제한이
너무 낮아 발생하는 문제라고 한다. 이 때 아래와 같이

sudo sysctl -w kern.maxproc=2500
sudo sysctl -w kern.maxprocperuid=2500

명령어를 통해 제한값을 높여주면 해결된다. 맥은 설치는 쉬운데 왜이리도
설정해줘야 많은지 모르겠다.
