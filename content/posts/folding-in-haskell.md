---
title: "Folding in Haskell"
date: 2019-05-01T17:56:20+09:00
categories:
- haskell
tags:
- folding
keywords:
- tech
---

<!-- toc -->

# Folding in Haskell

취업을 위한 포트폴리오 준비 작업으로 바쁜 가운데, Functional
Programming에 대해 관심이 생겨 `Haskell`이라는 언어를 배우기
시작했다. (알고리즘이나 데이터베이스 등 배울 것이 많은 데 갈수록
태산이다.) 대학교 시절, xmonad 윈도우즈 매니저를 사용하면서 접한
언어를 이렇게 뒤늦게 배우게 될 줄은 꿈에도 몰랐다.

대표적인 함수형 언어로 알려진 Haskell 에는 `Folding` 이라는 특별한
개념이 등장한다. `Haskell Wiki`에서는 `Folding`을 아래와 같이 설명하고
있다.

> In functional programming, fold (or reduce) is a family of higher
> order functions that process a data structure in some order and
> build a return value. <br>
> Typically, a fold deals with two things: a combining function, and a
> data structure (typically a list of elements). The fold then
> proceeds to combine elements of the data structure using the
> function in some systematic way.

리스트와 같이 여러 원소들로 이루어진 데이터 구조의 각 원소들을 각각
인자(arguments)로 넘긴 함수에 대입하고, 그 결과를 원소 타입으로
반환하는 것이 `fold` 함수의 역할이다. 다시 말해서, `spine` 형태의
데이터 구조를 특정한 함수를 이용하여 접고(`fold`) 줄여서(`reduce`)
결과값을 얻는 것이 그 역할이라고 정리하면 이해하기 쉽다.

먼저, 아래의 예제를 살펴보자.

```hs
> foldr (+) 1 [1..3]
7

> :t foldr
foldr :: Foldable t => (a -> b -> b) -> b -> t a -> b
```

`foldr`은 `(a -> b -> b)` 형태의 함수와 `b`, `t a` 인자 3 개를 입력
받아 `b` 타입을 반환한다. 즉, (1 + (2 + (3 + (1))) 과 같은 형식으로
`fold` 를 진행하여 결국 답은 7이 된다. 이 때, 각 괄호를 reduce한
결과는 `foldr` 대신 `scanr` 키워드를 사용하면 아래와 같이 얻을 수
있다.

```hs
> scanr (+) 1 [1..3]
[7,6,4,1]
```

그렇다면, 반대로 괄호를 움직여 evaluation의 방향을 왼쪽에서 오른쪽으로
바꿔보면 어떨까?

```hs
> foldl (+) 1 [1..3]
7
> scanl (+) 1 [1..3]
[1,2,4,7]
> :t foldl
foldl :: Foldable t => (b -> a -> b) -> b -> t a -> b
```

`foldr`과 달리 `foldr`은 전달한 함수에 인자로 `(a -> b -> b)`가 아닌
`(b -> a -> b)`를 전달한다. 이 때문에 결과값은 같더라도
평가(Evaluation)의 순서가 ((((1) + 1) + 2) + 3) 달라지게 된다. 이
때문에 `scanl`의 결과는 `[1,2,4,7]`이 되는 것이다.

이러한 `fold`의 장점은 갖가지 재귀 함수들을 엄청나게 간단하게 만들 수
있다는 것이다. 예를 들면, reverse 함수의 경우 보통 아래와 같이 작성할
수 있다.

```hs
myReverse :: [a] -> [a]
myReverse [] = []
myReverse (x:xs) = myReverse xs ++ [x]
```

하지만, `fold`를 사용하면, 아래와 같이 축약된 형태로 간단하게 작성할
수 있다.

```hs
-- pointfree 함수 형태로 작성
myReverse :: [a] -> [a]
myReverse = foldl (flip (:)) []
```

이처럼 함수형 프로그래밍에서 `fold` 또는 `reduce`는 인자로 전달한
데이터 구조를 특정한 함수를 이용하여 반환값을 구성하기 위한 HOF
(Higher Order Functions, 함수를 인자로 취하거나 반환값으로 함수를
반환하는 함수)의 한 가지이다. 문서 대부분이 영어로 되어 있고 함수형
언어에 대해서는 아직까지 관심을 가지는 사람이 많이 없어 공부하기에는
쉽지 않지만 하나씩 정리해 나가다 보면 언젠가는 문서를 만들 수 있을
정도로 자료가 많아질 것이라 기대한다.
