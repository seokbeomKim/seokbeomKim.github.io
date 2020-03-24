---
title: "goto statement"
date: 2020-03-25T00:47:49+09:00
categories:
- c
tags:
- goto
---

## 개요

학부 시절 c언어를 배울 때 'goto' 문을 사용하는 것을 터부시할 정도로 절대 사용하면 안되는 문법으로 배웠다. 그 이유는 자세하게 알려주지 않았지만 되도록이면 goto 를 사용하지 않고 분기나 객체를 이용하도록 코딩을 했었고 저학년에서 고학년으로 올라갈수록 c언어 대신 자바나 c++, c# 등을 배우면서 goto는 머릿속에서 잊혀져갔다.

입사하고 나서 드라이버 코드를 보니 간간히 goto 문이 사용된 것들을 보고 이것이 과연 리팩토링을 해야하는 대상인가에 대해 잠시 생각해보았다. 만약 아래와 같이 코드가 진행될 경우, 반드시 나머지 코드를 분기문으로 처리해야할 필요가 있을까? 아니면 여기저기에 `return` 문을 사용해서 에러가 발생할 경우에 곧바로 함수를 빠져나가게 해야할까?

``` c++
func() {
    int ret = 0;

    ret = check_something();
    if (ret < 0) {
        printk(KERN_ERR "ERROR!\n");
    } else {
        // remains..
    }
}

func2() {
    int ret = 0;

    ret = check_something();
    if (ret < 0) {
        printk(KERN_ERR "ERROR!\n");
        return -EINVAL;
    }

    // remains..
    return ret;
}
```

Stack Overflow에서 관련 내용을 찾아보니 재미있는 코드를 발견했다. 코드 곳곳에서 보이던 `do - while(0)` 이 대체 왜 사용되는 걸까 하고 궁금했었는데, [[링크|https://stackoverflow.com/questions/243967/do-you-consider-this-technique-bad]]를 보니 이제서야 왜 사용했는지를 알 수 있었다. 정답은 없지만 최대한 간결하고 이해할 수 있도록 짤 수만 있다면 그러한 문법에 무슨 문제가 있을까? 무조건 사용을 하지 말아야 할 것이 아니라, 때에 따라서 적절하게 사용하고, 문제가 되지 않는다면 goto로 간결하게 짤 수 있을 것이다. 함수가 길지 않고 여기 저기에 사용되지 않는다면 goto 문을 사용할 수 있지만 그렇지 않을 경우에는 되도록이면 분기문을 통해 적절하게 처리해야할 것이다.