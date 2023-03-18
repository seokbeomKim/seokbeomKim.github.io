---
title: "poll() 그리고 poll_wait()"
date: 2020-03-10T23:52:01+09:00
categories:
- kernel
tags:
- poll
- poll_wait
---

# 개요
업무 중에 카메라 드라이버에 관련된 이슈를 보다가 `poll()`과
`poll_wait()`이 지속적으로 사용되는 것을 볼 수 있었다. 이슈에 관련된
커널이 다소 오래되었기에 살펴보아야 하는 드라이버 코드도 레거시에
가까웠지만 `poll`을 이용하여 디바이스 드라이버의 인터럽트를 처리하는
것으로 확인하여 관련 내용을 정리하고자 한다.

리눅스 커널에서 제공하는 `poll` 함수에 대해서 원문으로 작성된 여러
출처들이 있었지만 아무래도 처음부터 원문을 읽고 이해하기에는 다소
어려움이 있었다. falinux에 작성된 문서를 기반으로 아래와 같이 개념적인
내용만 재정리하는 방식으로 포스팅을 작성하려 한다.

# poll()과 select()
non-blocking I/O를 사용하는 *유저 레벨 애플리케이션*은 종종 `poll()`
과 `select()` 시스템 콜을 사용한다. poll, select는 기본적으로 같은
기능을 한다. 둘 다 blocking 없이 하나 이상의 파일들을 읽거나 쓸 수
있도록 프로세스가 결정할 수 있도록 한다. 이러한 특성으로 인해 블로킹
없이 input 또는 output 스트림을 사용해야 하는 애플리케이션에서 종종
사용된다. select와 poll은 같은 기능이지만 각각 BSD Unix, System V
solution이라는 두 개 그룹에서 구현되면서 각기 다른 이름을 가지게
되었다.

2.x 리눅스 커널에서는 select를 모델로 한 디바이스 모델 기반이었지만
2.1.23 버전으로 되면서 poll 시스템 콜이 새롭게 소개되었다.

``` c++
unsigned int (*poll) (struct file *, poll_table *);
```

# 동작 방식
(사용자) 애플리케이션에서는 poll 함수를 이용해 디바이스 장치
노드파일의 파일 연산으로 정의된 poll 인터페이스를 호출한다.

아래의 예제 코드를 보면 직관적으로 동작 시나리오가 와닿을
것이다. 먼저, 애플리케이션의 코드를 먼저 살펴보자.

``` c++
struct pollfd
{
	int fd;		    // 파일 디스크립터 번호를 등록한다.
	short events;	// 요구하는 이벤트
	short revents;	// 반환된 이벤트

}

#include <sys/poll.h>

int main( int argc, char **argv )
{
	int 	fd1,fd2;
	int	retval;
	struct pollfd Events[2];

	fd1 = open("디바이스1", O_RDWR | O_NOCTTY );
	fd2 = open("디바이스2", O_RDWR | O_NOCTTY );

	memset ( Events, 0 ,sizeof(Events) );

	Events[0].fd = fd1;
	Events[0].events = POLLIN | POLLERR;
	Events[1].fd = fd2;
	Events[1].events = POLLOUT;

	while( 1 )
	{
		retval = poll( (struct pollfd *)&Events, 2, 5000);

		if( retval < 0 )
			printf("poll err\n");
		else if( 0 == retval )
			printf("No event!!\n")l
		else
		{
			if( POLLERR & Events[0].revents )
				printf("장치 에러\n");
			else if( POLLIN & Events[0].revents )
			{
				read(fd1, ~,~);
			}
			else if (POLLOUT & Events[1].revents )
			{
				write(fd2, ~, ~);
			}
		}
	}

	close(fd1);
	close(fd2);
}
```

위 예제는 출처에 작성된 예제 코드 그대로이다. 장치 노드를 open 시스템
콜을 통해 파일 디스크립터 형태로 받아놓고 해당 파일 디스크립터를 poll
함수에 넘겨 디바이스 드라이버에 정의되어 있는 poll 함수를 호출하는
방식이다. 이 때, 디바이스 드라이버에서 poll 요청을 어떻게 처리하는냐에
따라, 그리고 해당 디바이스에 대한 이벤트에 따라 poll의 반환값이
달라지게 된다.

그렇다면, 디바이스 드라이버 내에서는 어떤 방식으로 구현되는지 아래
코드를 살펴보자.

``` c++
struct file_operations kerneltimer_fops =
{
       .owner   = THIS_MODULE,
       .read    = kerneltimer_read,
       .write   = kerneltimer_write,
       .poll    = kerneltimer_poll,
       .open    = kerneltimer_open,
       .release = kerneltimer_release,
};

DECLARE_WAIT_QUEUE_HEAD(WaitQueue_Read);
unsigned int XXX_poll( struct file *file, poll_tablr *wait)
{
	int mask = 0;

	poll_wait( file, &WaitQueue_Read, wait );
	if( 쓰기 가능 ) mask |= (POLLIN | POLLRDNORM );

	return mask;
}

```

디바이스 드라이버는 읽기나 쓰기가 가능해지면 이에 따라 깨어나 디바이스
드라이버에 맞는 수행을 하게 되는데, 이러한 이벤트에 따라 동작
시나리오를 구현하기 위해 디바이스 드라이버 내에 poll 함수를
등록해두어야 한다.

`poll()` 함수를 호출하는 애플리케이션에서 커널이 주기적으로 어떤
이벤트를 모니터링 할지를 디바이스 드라이버에 전달해주면, 디바이스
드라이버에서는 해당 이벤트가 발생할 때까지 기다리다가, ISR 등으로 인해
디바이스 드라이버의 poll_wait 이 풀리게 되면 `poll()` 호출로 sleep
상태에 있던 프로세스를 깨우게 된다.

이러한 `poll` 시스템 콜이 필요한 이유는 디바이스 드라이버에서 입출력에
필요한 데이터가 준비될 때까지 프로세서가 대기하지 않도록 하기
위함이다.

애플리케이션은 디바이스 드라이버에게 "A, B, C 사건이 일어날 때
알려줘. 그 때까지 좀 잘게" 라고 말하는 것이 `poll()` 이고, 디바이스
드라이버는 해당 이벤트가 일어날 때까지 기다리고 있다가 ISR에 의해
이벤트 조건이 충족되면 POLLOUT, POLLIN, POLLERR, POLLWRNORM, ... 과
같은 마스킹 정보를 통해 애플리케이션에게 디바이스 드라이버의 데이터가
준비되었음을 알리는 것이 매커니즘의 핵심이다.

# 출처
- http://forum.falinux.com/zbxe/index.php?document_srl=567919&mid=lecture_tip
