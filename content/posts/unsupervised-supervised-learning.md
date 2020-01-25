---
title: "비지도 학습 알고리즘과 지도 학습"
date: 2019-05-06T15:31:38+09:00
categories:
- Machine Learning
tags:
- 비지도 학습
- 지도 학습
keywords:
- tech
---

# 개요
프로젝트 진행을 위해 필요한 머신러닝을 배우기 위해 책을 펼쳤다. 제일
먼저 나오는 개념이 지도 학습(Supervised Learning)과
비지도(Unsupervised Learning)이었는데 어디에도 학습이 정확이
무엇인지에 대한 내용이 없었다.

# 학습이란 무엇인가?
질문에 대한 답은 쉽게 찾을 수 있었다.([해당
링크](https://www.quora.com/What-does-learning-mean-in-machine-learning))

``` text
A model with a set of parameters transforms the input into an output,
this generates a signal from which the model updates the parameters to
produce a new output.

In the supervised learning scenario, the signal is the error between
the model's estimate and the ground truth (the correct answer).

In an unsupervised sceneario it can be a constraint (a measure of
sparsity, maintaining low entropy within the parameters, maximizing
the separation between cluster centroids).

In reinforcement learning, the model receives a signal and can
differentiate how positive of a reward it is (e.g. you're doing
better, keep going, or colder colder colder).

The learning is basically what happens after the model has produced an
estimate given a new observation and a signal directing it towards
minimizing a cost (= maximizing an objective). An additional
requirement for the model is to perform similarly for multiple and
different operations.

```

머신 러닝에서 학습이란, 기본적으로 새로운 데이터가 주어졌을 때 설계한
모델이 최대한 객관성을 가지도록 하기 위해 일어나는 것이다. 그러한
학습이 일어나는 이벤트를 출처(위)에서는 `generating a signal`라고
표현했다.

# 지도 학습 (Supervised Learning)
지도 학습은 이미 알려진 사례를 바탕으로 일반화된 모델을 만들어 의사
결정 프로세스를 자동화하는 것들이다. 다시 말해, 알고리즘에 입력과
기대하는 출력을 제공하고 알고리즘은 주어진 입력에서 원하는 출력을
찾는다. 지도 학습의 예는 아래와 같다.

* 편지 봉투에 손으로 쓴 우편번호 숫자 판별
  - IN: 스캔한 편지 봉투 이미지
  - OUT: 우편 번호 (눈으로 확인해서 원하는 출력 값을 기록해놔야 한다.)

* 의료 영상 이미지에 기반한 종양 판단
  - IN: 이미지
  - OUT: YES or NO

# 비지도 학습
비지도 학습은 알고리즘에 입력은 주어지지만 기대하는 출력값은 주어지지
않는다. 블로그 글의 주제 구분, 고객들을 취향이 비슷한 그룹으로 묶기,
비정상적인 웹사이트 접근 탐지 등을 예로 들 수 있다.

# 출처
* https://www.quora.com/What-does-learning-mean-in-machine-learning
