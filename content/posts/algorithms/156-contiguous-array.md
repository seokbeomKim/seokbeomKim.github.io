---
draft: true
title: "525. Contiguous Array"
date: 2022-02-04T23:21:10+09:00
tags:
- 525번
- HashMap
categories:
- Leetcode
---

# HashMap을 이용한 문제

문제를 읽고 HashMap을 이용한 방법이 한번에 와닿지 않아 이를 다시 한번 더 정리하고자 한다.
이번 "Contiguous Array" 문제는 배열 내의 0, 1 개수가 동일한 최대 길이를 구하는 문제이다.
즉, [0,1,0], [0,1,0,1,1] 등은 각각 2, 4가 된다. 이를 풀기 위해서는 {count: index} 로
구성된 HashMap 을 이용한다. 이 때 count 값은 0부터 시작하여 0일 경우 -1, 1일 경우 +1을
더하여 구하면 주어진 배열에 대해 아래와 같이 1차원 그래프가 나온다.

(예) [0, 1, 0, 1, 1, 1, 0]

![A Graph of Counter Value](/img/algorithms/156_contiguous_array.png)

여기서 중요한 점은 동일한 count 값을 가지는 포인트가 최대 길이가 된다는 점이다. HashMap의
초기값을 {0: -1} 이라고 했을 때, 예제 배열에서 [0, 1] 이 지난 이후의 해시맵은 아래와 같다.

```python
{
        # count: index
        0: -1,
        -1: 0
}
```
인덱스 1에서 count 값은 0이므로, 기존에 저장되어 있던 map[0] 과의 차이를 구해주면
최대길이 2를 얻을 수 있다. 배열의 바이너리 값을 count 값을 이용한 또 다른 값의 형태로 변환하고
이를 이용하여 해답을 찾는 방식이 매우 새로웠던 문제이다.
