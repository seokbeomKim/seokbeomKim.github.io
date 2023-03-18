---
title: "switch 구문과 if-else 구문"
date: 2020-02-26T23:56:18+09:00
categories:
- c
tags:
- switch
---

# 개요
실행 시간 단축을 위해 어떤 방법이 가능할지 고민하던 중 아래와 같은
case 구문을 보았다.

``` c++
int switch_example(unsigned int flag) {
    switch (flag) {
    case FLAG_A:
	// do A
	break;
    case FLAG_B:
	// do B
	break;
    case blabla:
	// blabla...
	break;
    default:
	printk(KERN_ERR "ERROR!\n");
    }

    return 0;
}
```

# 함수 포인터 배열 사용하기
if-else 를 사용하지 않고 굳이 switch 문을 사용하는 이유가 있을까? 학부
시절, switch문은 되도록 지양하고 if-else를 사용해야 한다는 얘기를
들었던 기억이 났다. 하지만 if-else 구문을 사용하면 여러 개의 branch 가
생기기 때문에 처음 위 예제로 간단하게 작성한 코드를 아래와 같이
변환하려 했었다.

``` c++
int use_array_example (unsigned int flag) {
    void* handler[] = {
	handler_A,
	handler_B,
	handler_C
    };

    handler[flag]();
}
```

사용할 flag는 정해져 있고 함수 포인터를 담고 있는 배열을 사용한다면
불필요한 분기로 인한 성능 손실을 없애고 곧바로 호출할 수 있기 때문에
위와 같이 개선하려 했다. 하지만, 막상 switch 문에 대해 구글링 해보니
아래와 같은 답변을 찾을 수 있었다.

# switch 문과 컴파일러 최적화
https://www.geeksforgeeks.org/switch-vs-else/ 내용에 따르면, switch
문을 사용할 경우 컴파일 시에 'jump table(lookup table)' 또는 hash
list를 만들어 최적화를 시도하기 때문에 단순하게 if-else 를 사용할
때보다 실행 속도 측면에서 더 유리하다고 한다.

분명 학부시절 때 알아야 했을 기본적인 내용이지만, 몇 년이 지나서도
이러한 기본적인 내용을 계속해서 살펴보게 되는 것 같다. 배우고 기억하려
해도 끝이 보이지 않는다.
