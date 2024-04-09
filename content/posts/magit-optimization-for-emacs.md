---
draft: true
title: "Emacs에서 magit 최적화하기"
date: 2021-01-01T13:42:08+09:00
categories:
- Etc
tags:
- emacs
- magit
---

## 개요

이맥스에서 magit 을 이용하여 수정 상태나 커밋 메시지를 확인할 때 오래
걸리는 문제가 있었다. magit 의 매뉴얼 페이지를 보아도 원하는 것은
없었는데, [Speeding up magit - Jake
McCray](https://jakemccrary.com/blog/2020/11/14/speeding-up-magit/)
블로그의 내용으로 문제를 해결할 수 있었다.

링크된 블로그에서는 magit을 이용하면서 어디에서 속도가 느려지는지를
확인하기 위해 `magit-refresh-verbose` 을 이용하는 방법을 가이드해주고
있다. 커밋 메시지나 깃 상태를 확인할 때 실행되는 hook function 들에서
몇 초간 소모되는지를 나타내주는데, 이를 이용해서 태그와 브랜치 등의
헤더 정보, 코드 diff를 가져오는데 엄청난 시간이 걸린다는 것을 알게
되었다.

```
Refreshing buffer ‘magit: example-repo’...
  magit-insert-error-header                          1e-06
  magit-insert-diff-filter-header                    2.3e-05
  magit-insert-head-branch-header                    0.026227
  magit-insert-upstream-branch-header                0.014285
  magit-insert-push-branch-header                    0.005662
  magit-insert-tags-header                           1.7119309999999999
  magit-insert-status-headers                        1.767466
  magit-insert-merge-log                             0.005947
  magit-insert-rebase-sequence                       0.000115
  magit-insert-am-sequence                           5.1e-05
  magit-insert-sequencer-sequence                    0.000105
  magit-insert-bisect-output                         5.3e-05
  magit-insert-bisect-rest                           1.1e-05
  magit-insert-bisect-log                            1e-05
  magit-insert-untracked-files                       0.259485
  magit-insert-unstaged-changes                      0.031528
  magit-insert-staged-changes                        0.017763
  magit-insert-stashes                               0.028514
  magit-insert-unpushed-to-pushremote                0.911193
  magit-insert-unpushed-to-upstream-or-recent        0.497709
  magit-insert-unpulled-from-pushremote              7.2e-05
  magit-insert-unpulled-from-upstream                0.446168
Refreshing buffer ‘magit: example-repo’...done (4.003s)
```

문제가 되는 (특별하게 느려지는) 부분은 속도 뒤에 !! 표시가 되는데 해당
함수들이 사용하는데 잘 쓰이지 않는다면 과감하게 아래와 같이
제거해주자. 필자는 변경된 코드 확인과 커밋 메시지만을 주로 확인하므로
아래와 같이 설정하였다.

```
  ;; remove unnecessary magit function on revision section hook
  (remove-hook 'magit-revision-sections-hook 'magit-insert-revision-headers)
  (remove-hook 'magit-revision-sections-hook 'magit-insert-revision-notes)
  (remove-hook 'magit-revision-sections-hook 'magit-insert-revision-diff)
  (remove-hook 'magit-revision-sections-hook 'magit-insert-revision-tag)
  (remove-hook 'magit-revision-sections-hook 'magit-insert-xref-buttons)
  (add-hook 'magit-revision-sections-hook 'magit-insert-revision-message)

  ;; remove unnecessary magit function on showing status
  (remove-hook 'magit-status-sections-hook 'magit-insert-tags-header)
  (remove-hook 'magit-status-sections-hook 'magit-insert-status-headers)
```

커널 공부를 위해 커밋 메시지 살펴볼 볼때마다 엄청나게 걸리던 시간은
1초도 안되는 시간에 매끄럽게 볼 수 있게 되었다. 성능 이슈가 생길
정도로 너무 많은 기능을 넣을 필요는 없는데 magit은 이러한 부분에
있어서 너무 매정한 것 같다.
