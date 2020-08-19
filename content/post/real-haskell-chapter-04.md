---
title: "(.) 와 ($) 의 차이"
date: 2020-08-17T18:08:58+09:00
categories:
- haskell
tags:
- function application
toc: false
---

## 개요

최근 하스켈로 조그만 프로젝트를 시작하기 위해 *Real World Haskell* 이라는 책 한 권을 구입하여 공부하기 시작했다. *Functional Programming* 패러다임 자체가 익숙하지 않기에 주어진 문제를 해결하기 위한 접근 방식부터 차근차근 배워나가려 하고 있지만 쉽지 않다. 여타 주요 언어에서 제공하는 **loop**의 개념이 없고 함수만으로 이루어진 *recursive*와 *pattern matching* 또는 *function application* 등으로 표현되기에 쉽지가 않다. **Higher-order function**으로 이루어지는 하스켈의 함수에서는 **currying**을 통해 여러 개의 인자를 갖는 함수를 표현할 수 있다. 이러한 개념과 함께 설명되는 것이 포스팅의 타이틀에 해당하는 (.)과 ($) 연산자인데 각각 **Function Composition**과 **Function Application**을 의미한다.

## Higher-Order Function

어째서 **higher-order functiion** 이라는 이름을 갖게 되었을까. 고차함수라 부르는 이 함수는 *Function Proramming* 에서는 적어도 아래 조건 중 하나 이상을 만족하면 고차함수 HOF 라 한다.

1. 하나 이상의 함수를 인자로 받는다.
2. 함수를 결과로 반환한다.

## Function Application & Function Composition

이제 `($)` 연산자를 살펴보자. 연산자는 아래와 같이 정의된다.

    ($) :: (a -> r) -> a -> r

`($)` 연산자는 함수를 인자로 전달받으며 해당 함수를 인자로써 적용한다. 이러한 의미로 `f $ a`는 `f a`와 같다. 그렇다면, 연산자 `(.)`는 어떨까?

    (.) :: (b -> c) -> (a -> b) -> (a -> c)

`(.)` 연산자는 함수 두 개를 인자로써 전달받고 두 개를 합성하는 역할을 한다. 때문에 `(f . g) a` 는 `f (g a)`와 같으며 앞서 함수를 인자로써 넘기는 것과 확연히 다른 의미를 갖는다. 이러한 Function Composition을 이용하면 여러 개의 함수를 합성하여 아래와 같이 사용할 수 있다.

    > getDefineName = head . tail . words
    > getDefineName "define DLT_CHAOS 5"
    "DLT_CHAOS"

## 참고 자료

- <https://www.quora.com/What-is-the-difference-between-and-in-Haskell>
- <https://medium.com/@la.place/higher-order-function-%EC%9D%B4%EB%9E%80-%EB%AC%B4%EC%97%87%EC%9D%B8%EA%B0%80-1c61e0bea79>