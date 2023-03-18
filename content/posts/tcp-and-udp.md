+++
title = "TCP와 UDP의 차이점"
date = 2019-05-21T15:27:08+09:00
categories = ["web"]
tags = ["udp", "tcp"]
+++

예전에 TCP, UDP에 대해서 정리해놓은 것들을 찾을 수 없어 블로그
페이지로 정리하고자 포스팅을 새로 만들었다. 앞으로 두고두고 찾아보게
될 페이지므로 향후 커널 소스 분석을 통해 TCP, UDP와 관련된 부분이 나올
경우 포스팅을 업데이트 할 예정이다.

방산 업체에서 무인 정찰기를 개발할 당시에도 중요 데이터는 모두 `TCP`를
이용해 송수신하고 영상과 같은 정보는 `UDP`를 이용해 전달받았다. 당시에
구현된 코드를 보면서 이전에 프로토콜 사용에 있어서 어디부터 어디까지를
UDP 혹은 TCP로 해야 하는가에 대해 논란이 있었을거라 예상했지만 코드를
변경할 수 없어 아쉬웠던 적이 있었다.

각설하고 이 포스팅에서는 리눅스 커널 소스에서 TCP와 UDP, 즉 L4
전송계층에 대한 구현이 어떤 식으로 되어있는지 살펴볼 것이다.


# TCP (Transmission Control Protocol)
먼저, TCP(Transmission Control Protocol)는 `connection-oriented`
프로토콜이다. 연결이 수립되기 전까지는 데이터를 송수신하지 않으며,
데이터 송수신이 종료되면 반드시 연결을 닫아야 한다. 이러한 특성 덕분에
TCP는 아래와 같은 특징을 갖는다.

1. 데이터 송수신에 신뢰성이 보장된다.
2. 에러 체크 기능을 제공한다.
3. 수신자에게 패킷이 순서대로 전달된다.
4. UDP보다 상대적으로 느리다.
5. 패킷 손실로 인한 패킷 재전송이 가능하다.
6. 헤더 크기가 20bytes이다.
7. HTTP, HTTPS, FTP, SMTP, Telnet 등에 사용된다.

먼저 앞서 언급한 것들에 대해서 커널 소스를 통해 자세히 살펴보자. tcp에
관련된 코드는 `/net/ipv4/tcp.c` 하위 경로 내에 위치한다. (분석으로는
IPv4를 먼저 진행하고 충분히 이해한 뒤 추후에 IPv6에 대해서 분석한 뒤
업데이트 하고자 한다.)

> 코드를 살펴보면 EXPORT_SYMBOL 코드를 많이 볼 수 있을 것이다. 로드
> 가능한 모듈이 삽입되면 해당 모듈이 가지고 있는 커널 함수들과 데이터
> 구조들은 반드시 현재 실행 중인 커널에 로드되어 reference 될 수
> 있어야 한다. 하지만 모듈을 로드하는 Module Loader는 모듈에서
> 명시적으로 export 하지 않는 한 모듈이 가지고 있는 모든 심볼들을
> export 하지 않는다.<br>또 한가지 재밌는 점은 라이센스에 따라 해당
> 심볼로의 접근을 제한할 수 있다는 것이다. cscope를 통해 탐색해보면
> 알겠지만, __EXPORT_SYMBOL 함수에는 심볼 이름 외에 라이센스 그룹에
> 대한 정보를 전달하게 되어 있어 같은 라이센스 구릅인지 아닌지를
> 구분하여 액세스 여부를 허용/거부 하도록 되어 있다.

## 초기화 코드

``` c++
void __init tcp_init(void)
{
    struct sk_buff *skb = NULL;
    unsigned long nr_pages, limit;
    int i, max_share, cnt;
    unsigned long jiffy = jiffies;

    BUILD_BUG_ON(sizeof(struct tcp_skb_cb) > sizeof(skb->cb));

    percpu_counter_init(&tcp_sockets_allocated, 0);
    percpu_counter_init(&tcp_orphan_count, 0);
    tcp_hashinfo.bind_bucket_cachep = ...
```

TCP 초기화 코드는 `__init` 이라는 키워드와 함께 심볼이 정의되어 있다.

> __init에 관한 설명은 $KERNEL_SOURCE/arch/um/include/shared/init.h
> 에서 찾아볼 수 있다. 이 키워드는 해당 함수를 초기화 함수로 표시하는
> 역할을 한다. 커널은 초기화 프로세스 도중에 초기화에 관련된 것으로
> 간주하고 메모리 리소스를 해제하거나 초기화 프로세스 과정에서 표시된
> 함수나 데이터들을 이용한다.<br>
> [링크](https://stackoverflow.com/questions/8832114/what-does-init-mean-in-the-linux-kernel-code)를
> 살펴보면 재미있는 예시가 하나 있다. 'Freeing unused kernel memory'와
> 같은 메시지를 나타내는 것을 그 예로 들 수 있다.



# 출처
* https://www.geeksforgeeks.org/differences-between-tcp-and-udp/
* [LWN - On the value of EXPORT_SYMBOL_GPL](https://lwn.net/Articles/154602/)
* [Naver D2 - TCP/IP 스택 이해하기](https://d2.naver.com/helloworld/47667)
