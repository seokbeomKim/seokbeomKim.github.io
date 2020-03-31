---
title: "BSD 버전 Linked List"
date: 2020-04-01T00:26:52+09:00
categories:
- linux
- programming
- c
tags:
- queue
- bsd
- list
keywords:
- tech
toc: false
---

## 개요

사내에서 소스 파일에 대한 라이센스를 정리하기 시작하면서 기존 애플리케이션에서 리눅스의 pipe 를 이용하여 구현된 메세지 큐를 연결 리스트로 재작성하는 작업을 맡게 되었다. 처음에는 리눅스의 커널에서 제공하는 `list.h` 를 사용하지 못해서 연결 리스트를 학부시절에 사용하던 방식으로 직접 구현하고자 하였다. 하지만 조금 더 찾아보니 BSD 버전의 연결 리스트가 `<sys/queue.h>` 의 형태로 존재하고 있었고 현재 FreeBSD에 포함되어 있는 queue.h 와는 다르지만 오래 전 공유하던 레거시 코드로서 여전히 리눅스 커널 내에 BSD 커널 라이브러리를 간직하고 있었다. 라이센스에 전혀 문제가 되지 않을 뿐만 아니라 필요한 메시지 큐를 구현하기 위한 매크로가 알기 쉽게 정의되어 있어 작성하는데에는 크게 어렵지 않았다. 대신, 불필요하게 잘못된 메모리 접근으로 인한 코드를 디버깅하는데 시간이 많이 걸렸다.

## queue.h

작업에 사용했던 queue.h 파일(<https://github.com/freebsd/freebsd/blob/master/sys/sys/queue.h> 참고)에는 LIST와 TAILQ, CIRCLEQ가 구현되어 있었다. 링크는 최신버전의 라이브러리라 Circular Queue가 사라져있을 것이다. 리눅스의 `list.h`와 마찬가지로 BSD의 `queue.h`도 리스트를 사용하기 위해 재미있는 방법을 사용한다. 먼저 man-page에 기술되어 있는 예시를 시작으로 하나씩 살펴보자.

``` c++
TAILQ_HEAD(tailhead, entry) head = TAILQ_HEAD_INITIALIZER(head);
struct tailhead *headp;		     /*	Tail queue head. */
struct entry {
    ...
    TAILQ_ENTRY(entry)	entries;     /*	Tail queue. */
    ...
} *n1, *n2, *n3, *np;

TAILQ_INIT(&head);			     /*	Initialize the queue. */

n1	= malloc(sizeof(struct entry));	     /*	Insert at the head. */
TAILQ_INSERT_HEAD(&head, n1, entries);

n1	= malloc(sizeof(struct entry));	     /*	Insert at the tail. */
TAILQ_INSERT_TAIL(&head, n1, entries);

n2	= malloc(sizeof(struct entry));	     /*	Insert after. */
TAILQ_INSERT_AFTER(&head, n1, n2, entries);

n3	= malloc(sizeof(struct entry));	     /*	Insert before. */
TAILQ_INSERT_BEFORE(n2, n3, entries);

TAILQ_REMOVE(&head, n2, entries);	     /*	Deletion. */
free(n2);
                    /*	Forward	traversal. */
TAILQ_FOREACH(np, &head, entries)
    np-> ...
```

먼저, `TAILQ_HEAD`부터 살펴보면 매크로를 통해 인자로 넘긴 이름으로 구조체를 하나 설정하는 것을 알 수 있다. 예를 들어 아래와 같이 정의된 자료형을 TAILQ 형태로 연결하고 싶다면,

``` c++
struct message {
    int idx;
    TAILQ_ENTRY(message) entries;
};

TAILQ_HEAD(msg_head, message) head; // struct msg_head head 와 같다.

#define	TAILQ_ENTRY(type)						\
struct {								\
	struct type *tqe_next;	/* next element */			\
	struct type **tqe_prev;	/* address of previous next element */	\
	TRACEBUF							\
}
```
위의 코드처럼 정의하여 사용할 수 있다. 자료구조 안에 `TAILQ_ENTRY`를 사용함으로써 링크 객체를 포함하는 방식으로 구현한다. 위 예제에서, 연결 리스트는 `struct msg_head* head` 를 통해 접근할 수 있으며, head에 연결되는 노드들의 실제 데이터 `struct message` 자체는 `*head`가 갖는 `*tqh_first`, `**tqh_last`를 통해 얻을 수 있다. 위에서 `TAILQ_HEAD` 매크로를 통해 얻은 구조체의 구조는 아래와 같다.

``` c++
#define	TAILQ_CLASS_HEAD(name, type)					\
struct name {								\
	class type *tqh_first;	/* first element */			\
	class type **tqh_last;	/* addr of last next element */		\
	TRACEBUF							\
}
```

전체적인 연결을 다이어그램으로 나타내면 아래와 같다.
![TAILQ in BSD](/img/TAILQ_BSD.png)