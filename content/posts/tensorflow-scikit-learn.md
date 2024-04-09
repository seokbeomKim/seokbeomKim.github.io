---
draft: true
title: "텐서플로우(Tensorflow)와 사이킷런(Scikit-learn)의 차이"
date: 2019-05-06T17:05:11+09:00
categories:
- Machine Learning
tags:
- tensorflow
- scikit learn
keywords:
- tech
---

책장 속에서 잊혀져 갔던 머신러닝 책을 꺼내 읽기 시작했다. 책을 받았을
당시에는 회사 출장으로 읽을 시간이 없었는데 이제서야 몇 개월이
지나서야 마음이 안정되어 이 책을 꺼내보게 되었다.

각설하고, 책의 모든 내용이 사이킷런(Scikit-learn)을 이용하는데 문득
텐서플로우(Tensorflow)와의 차이점이 무엇인지 궁금해졌다. 통상적으로
머신러닝이라 하면 텐서플로우를 많이 쓰는데, 굳이 사이킷런을 사용하는
이유가 있을까 궁금해졌다.

왜 라이브러리가 아닌 프레임워크라 부르는지 모르겠지만, 이들은 분류,
회귀, 클러스터링, 비정상행위 탐지, 데이터 준비를 위한 다양한 학습
방법을 다루며 인공 신경망 메서드를 포함할 수도, 포함하지 않을 수도
있다.

# 차이점

출처에 따르면, 텐서플로우는 상대적으로 로우레벨 라이브러리에 가깝고
사이킷런은 하이레벨 라이브러리에 가깝다. 텐서플로우는 신경망이나
딥러닝을 위해 사용되는 데이터 계산, 연산을 위한 라이브러리며 신경망
네트워크 레이어 정의를 위한 메서드도 제공한다. 하지만 결정 트리, 논리
회귀, K-Means, PCA와 같은 머신러닝 메서드는 제공하지 않는다.

이에 비해, 사이킷런(Scikit-learn)은 데이터 마이닝과 머신러닝을 위한
라이브러리다. 딥러닝이나 강화 학습을 다루지 않지만 지도 학습, 비지도
학습에 관련된 다양한 메서드를 제공하기 때문에 간단하게 학습 알고리즘을
사용하고자 한다면 사이킷런이 사용하기 쉽다는 장점이 있다.


# 출처
* https://m.blog.naver.com/PostView.nhn?blogId=kimkanu&logNo=221116429423&proxyReferer=https%3A%2F%2Fwww.google.com%2F
* https://www.quora.com/What-are-the-main-differences-between-TensorFlow-and-SciKit-Learn
