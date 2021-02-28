+++
title = "state vs status"
date = 2021-02-28T12:27:08+09:00
categories = ["term"]
tags = ["state", "status"]
+++

## 개요

코드를 보다보면 state와 status를 구분하지 않고 사용하는 경우가 많다. 두 용어의
차이점이 무엇인지 명확하게 하기 위해 직접 찾아보니 [“state” or “status”? When
should a variable name contain the word “state”, and when should a variable name
instead contain the word
“status”?](https://softwareengineering.stackexchange.com/questions/219351/state-or-status-when-should-a-variable-name-contain-the-word-state-and-w)
스택오버플로우에 이미 관련된 질문이 올라와 있었다.

둘의 차이점은 간단 명료하게 아래와 같이 정리할 수 있다.

- status: 결과 (success/fail); "마지막 상태"
- state: 상태 (pending/dispatched)

앞으로는 둘을 잘 구분해서 사용해야겠다. 잘못된 코드만 보다보니 어떤 것이
맞는건지 기존에 알던 것이 잘못된 것처럼 인식이 되는데 정확히 알고 사용하도록
하자.
