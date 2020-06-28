---
title: "git prune"
date: 2020-06-27T22:40:53+09:00
draft: true
categories:
- vcs
tags:
- git
toc: false
draft: true
---

`git prune` 명령어는 `unreachable`한 git object를 로컬에서 제거하는
명령어이다.

`git prune` 수행 시에 `--dry-run --verbose` 옵션을 주면 실제
수행되지는 않고 어떻게 수행될지에 대한 시뮬레이션을 볼 수 있다.

```
$ git remote prune --dry-run --verbose
```
