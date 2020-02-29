---
title: "리눅스에서의 버퍼링 방식"
date: 2020-02-29T23:34:30+09:00
categories:
- kernel
tags:
- buffering
keywords:
- tech
toc: false
---

# 리눅스에서의 버퍼링 정책
리눅스에서는 파일 입출력을 할 때 물리적인 파일에 조회 및 기록의 횟수를 최소화하여 성능을 높이기 위해 버퍼링 정책을 사용하고 있다.

만약 write 호출로 데이터를 쓰기 명령을 전달하면 해당 파일 작업을 위한 버퍼에 기록을 해 두었다가 정책에 따라 특정 시점에 물리적인 파일에 기록을 수행한다. 리눅스에서 제공하는 버퍼링 정책에는 버퍼가 꽉 차면 물리적인 파일에 기록하는 Full Buffering과 꽉 차거나 개행문자가 오면 처리하는 Line Buffering, 버퍼를 사용하는 않는 Null Buffering 정책을 제공하고 있다.

디폴트 버퍼링 정책은 Full Buffering이며, **character 장치 파일에 대한 작업은 Line Buffering 정책을 사용한다.** 그리고 오류를 출력하는 stderr 파일 시스템은 Null Buffering을 사용한다. 

아래의 예제를 살펴보자.

``` c++
#include <stdio.h>
#include <unistd.h>
int main()
{
    putchar(‘e’);
    sleep(1);
    fputc(‘H’, stderr);
 
    putchar(‘h’);
    sleep(1); 
    fputc(‘e’, stderr);
 
    putchar(‘\n’);
    sleep(1); 
    fputc(‘l’, stderr);
 
    putchar(‘p’);
    sleep(1); 
    fputc(‘l’, stderr);
 
    putchar(‘u’);
    sleep(1); 
    fputc(‘o’, stderr);
 
    putchar(‘b’);
    sleep(1); 
    fputc(‘!’, stderr);
 
    putchar(‘\n’);
    sleep(1); 
    fputc(‘\n’, stderr);
 
    return 0;
}
```

표준 출력의 경우 Line Buffering을 사용하기 때문에 putchar('e') 구문을 호출하면 stdout 버퍼에 문자 e를 기록하지만 아직 개행 문자를 기록한 것은 아니므로 콘솔 화면에 출력하지 않는다. 이 후 fputc('H', stderr); 구문에 의해 'H'를 표준 에러에 출력하지만 표준 에러는 Null Buffering 이므로 콘솔 화면에 'H' 문자를 바로 출력한다.

# 출처
- http://ehpub.co.kr/tag/line-buffering/