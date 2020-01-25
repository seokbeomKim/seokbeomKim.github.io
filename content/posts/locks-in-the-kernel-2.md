---
title: "리눅스 커널 락 종류 (2/5)"
date: 2019-05-29T00:59:34+09:00
categories:
- O/S
- Linux
tags:
- mutex
- semaphore
- spinlock
- global kernel lock
keywords:
- tech
---

지난 번 포스팅에서는 리눅스 커널 락 중 하나인 스핀락(Spinlock)에 대해
기술하였다. 이번 포스팅에서는 뮤텍스(Mutex)에 대해서 기술하고자
한다. 많은 곳에서 뮤텍스는 세마포어의 카운트 값이 단순하게 1로
설정되었을 때를 말한다고 기술한다. 하지만 이것이 맞는 설명일까?

[참고 자료](https://www.tutorialspoint.com/mutex-vs-semaphore)에
따르면 뮤텍스는 공유 자원으로의 접근(Access)에 대한 상호 배제(Mutual
Exclusion)을 위한 수단이 `Mutex`라고 정의하고 있다. 이에 반해
`세마포어(Semaphore)`는 시그널 매커니즘으로서 스레드(또는 프로세스) 간
동기화가 주 목적으로, `wait` 함수를 호출한 스레드만이 뮤텍스를 신호를
보낼 수 있다는 점이 기능적인 특징이다.  쉽게 말해,
**세마포어(Semaphore)는 임계 구역(Critical Section)을 실행하려하는
여러 개의 프로세스들을 제한하며 동기화하고, 뮤텍스(Mutex)는 오직 한
번에 한 개 프로세스에서 자원에 대한 접근을 제한하는 것이 mutex이자
mutual exclusion이라는 목적이다.**

뮤텍스는 카운트 1인 세마포어처럼 상호 배제성을 가진 휴면 가능한
락이지만 세마포어보다 부가적인 제약 사항을 가지고 있다.

* 한 태스크는 한 번에 하나의 뮤텍스만 얻을 수 있다. 즉, 뮤텍스의 사용
  카운트 값은 항상 1이다.

* 뮤텍스를 얻은 곳에서만 뮤텍스를 해제할 수 있다. 이 때문에 한
  컨텍스트에서 얻은 뮤텍스를 다른 컨텍스트에서 해제할 수 없으므로,
  커널과 사용자 공간 사이의 복잡한 동기화에 사용하기에는 부적절하다.

* 재귀적으로 락을 얻고 해제할 수 없다. 같은 뮤텍스를 재귀적으로 여러
  번 얻을 수 없으며 해제된 뮤텍스를 한번 더 해제할 수도 없다.

* 뮤텍스를 가지고 있는 동안에는 프로세스 종료가 불가능하다.

* 인터럽트 핸들러나 후반부 처리 작업 내에서는 뮤텍스를 얻을 수 없으며,
  mutex_trylock() 함수도 사용할 수 없다.

* 뮤텍스는 공식 API를 통해서만 관리할 수 있다. 또한 뮤텍스를
  복사하거나 초기화 상태 전달, 재 초기화하는 작업은 불가능하다.

그렇다면 어떤 경우에 뮤텍스와 스핀락, 세마포어 중에서 뮤텍스를
선택해야 하는가? 뮤텍스와 세마포어의 선택에는 **동기화 여부**를,
뮤텍스와 스핀락의 선택에서는 **인터럽트 컨텍스트 여부와 락
사용시간**을 비교하여 선택할 수 있다.<br><br>

| 요구사항                                 | 추천 Lock     |
|------------------------------------------|---------------|
| 락 부담이 적어야 하는 경우               | 스핀락        |
| 락의 사용시간이 짧아야 할 때             | 스핀락        |
| 락 사용시간이 길 때                      | 뮤텍스        |
| 인터럽트 컨텍스트에서 락을 사용할 때     | 반드시 스핀락 |
| 락을 얻은 상태에서 휴면할 필요가 있을 때 | 반드시 뮤텍스 |

뮤텍스에 관련된 예제는 간단하다. 애초에 뮤텍스에 관련된 API가 간단할
뿐더러 락을 얻은 컨텍스트에서 해당 락을 해제해야 하는 제약사항이 있기
때문이다.

이제 뮤텍스를 사용하는 코드 예제를 간단하게 살펴보자. 먼저 유저
레벨에서 동작하는 애플리케이션 코드이다.

#include <stdio.h>
#include <unistd.h>
#include <pthread.h>
#include <string.h>

pthread_t tid[2];
pthread_mutex_t lock;
int counter;

void* trythis (void *arg) {
    pthread_mutex_lock(&lock);

    unsigned long i = 0;
    counter += 1;
    printf("\n Job %d has started\n", counter);

    for (i=0; i<(0x9999); i++);

    printf("\n Job %d has finished\n", counter);

    pthread_mutex_unlock(&lock);
    return NULL;
}

int main(int argc, char* argv[]) {
    int i = 0;
    int error;

    if (pthread_mutex_init(&lock, NULL) != 0) {
        printf("\nMutex init has failed\n");
        return 1;
    }

    while (i < 2) {
        error = pthread_create(&(tid[i]), NULL, &trythis, NULL);
        if (error != 0) {
            printf("\nThread can't be created: %s", strerror(error));
        }
        i++;
    }

    pthread_join(tid[0], NULL);
    pthread_join(tid[1], NULL);
    pthread_mutex_destroy(&lock);

    return 0;
}

`void* trythis(void* arg)` 함수 내 뮤텍스로 인해 스레드가 락을 얻은
순서(Thread 1 -> Thread 2)대로 실행되는 것을 확인할 수 있다.

그렇다면, 유저 레벨 애플리케이션이 아닌 커널 모듈에서는 뮤텍스를 어떤
식으로 사용할 수 있을까? 여기에 대한 예제는 [커널
문서](https://www.kernel.org/doc/htmldocs/kernel-locking/Examples.html)에서
쉽게 찾을 수 있었다.

#include <linux/list.h>
#include <linux/slab.h>
#include <linux/string.h>
#include <linux/mutex.h>
#include <asm/errno.h>

struct object
{
        struct list_head list;
        int id;
        char name[32];
        int popularity;
};

/* Protects the cache, cache_num, and the objects within it */
static DEFINE_MUTEX(cache_lock);
static LIST_HEAD(cache);
static unsigned int cache_num = 0;
#define MAX_CACHE_SIZE 10

/* Must be holding cache_lock */
static struct object *__cache_find(int id)
{
        struct object *i;

        list_for_each_entry(i, &cache, list)
                if (i->id == id) {
                        i->popularity++;
                        return i;
                }
        return NULL;
}

/* Must be holding cache_lock */
static void __cache_delete(struct object *obj)
{
        BUG_ON(!obj);
        list_del(&obj->list);
        kfree(obj);
        cache_num--;
}

/* Must be holding cache_lock */
static void __cache_add(struct object *obj)
{
        list_add(&obj->list, &cache);
        if (++cache_num > MAX_CACHE_SIZE) {
                struct object *i, *outcast = NULL;
                list_for_each_entry(i, &cache, list) {
                        if (!outcast || i->popularity < outcast->popularity)
                                outcast = i;
                }
                __cache_delete(outcast);
        }
}

int cache_add(int id, const char *name)
{
        struct object *obj;

        if ((obj = kmalloc(sizeof(*obj), GFP_KERNEL)) == NULL)
                return -ENOMEM;

        strlcpy(obj->name, name, sizeof(obj->name));
        obj->id = id;
        obj->popularity = 0;

        mutex_lock(&cache_lock);
        __cache_add(obj);
        mutex_unlock(&cache_lock);
        return 0;
}

void cache_delete(int id)
{
        mutex_lock(&cache_lock);
        __cache_delete(__cache_find(id));
        mutex_unlock(&cache_lock);
}

int cache_find(int id, char *name)
{
        struct object *obj;
        int ret = -ENOENT;

        mutex_lock(&cache_lock);
        obj = __cache_find(id);
        if (obj) {
                ret = 0;
                strcpy(name, obj->name);
        }
        mutex_unlock(&cache_lock);
        return ret;
}

# 출처
- [Mutex
  vs. Semaphore](https://www.tutorialspoint.com/mutex-vs-semaphore)
- [Using Semaphore in
  Linux](http://tuxthink.blogspot.com/2011/05/using-semaphores-in-linux.html)
- [mutex lock for linux thread
  synchronization](https://www.geeksforgeeks.org/mutex-lock-for-linux-thread-synchronization/)
- [An example of Kernel Locking](https://www.kernel.org/doc/htmldocs/kernel-locking/Examples.html)
