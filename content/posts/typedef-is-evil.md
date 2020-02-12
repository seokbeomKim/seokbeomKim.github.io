---
title: "typedef is evil"
date: 2020-02-13T01:12:37+09:00
categories:
- linux
tags:
- typedef
---

커널 쪽의 코드를 보다가 문득 커널 코드에 적용하는 코딩 규칙에 대해서
궁금해졌다. 관련 내용으로 검색하다보니 재미있는 포스팅 하나를
발견했다. [typedef is
evil](https://discuss.fogcreek.com/joelonsoftware1/10506.html) 이라는
제목의 포스팅이었다. 이 포스팅에서는 아래와 같이 사용하는 것을
비판하고 있다. 2000년도 초반에 작성된 것이니, 벌써 20년 가까이
되었는데도 불구하고 여전히 코드에 남아있다는 점이 아이러니하다.

``` c++
typedef struct foo {
	int bar;
	int baz;
} foot_t, *pfoo_t;
```

위와 같이 구조체에 대한 포인터를 정의할 때 typedef을 이용하지 말 것을
당부한다. 또한, `typedef unsigned long DWORD` 와 같은 것도
비판한다. 머신마다 크기가 다르기 때문에라고 하는데, 이 부분에 대해서는
동의하지는 못하겠다. 아키텍처별 코드라면 각 프로세서마다 dword, word의
크기가 정해져 있고 이를 데이터시트에 적합하도록 코딩하기 위해서는
dword와 word 라는 키워드를 정의하여 사용하는 것이 가독성에 유리할
것이라 생각하기 때문이다.

``` c++
typedef struct { pgdval_t pgd; } pgd_t;
#define pgd_val(x)	((x).pgd)
#define __pgd(x)	((pgd_t) { (x) } )
```

위는 ARM64 페이징 관련 코드를 살펴보다가 발견한 구조체 정의
부분이다. 위와 같이 구조체 안에 멤버로써 사용하는 타입에 대해서도 u64,
u32 대신 `pgdval_t`를 사용하고 있다. 커널 소스 내의 문서를 살펴보면
이러한 내용에 대해 아래와 같이 정의하고 있으며 좋지 않은 사례로써
pgdval_t 와 유사한 것을 인용하고 있다.

```
Please don't use things like ``vps_t``.
It's a **mistake** to use typedef for structures and pointers. When you see a

	vps_t a;

in the source, what does it mean?
In contrast, if it says

	struct virtual_container *a;

you can actually tell what ``a`` is.

Lots of people think that typedefs ``help readability``. Not so. 
```

커널 문서에 따르면, 단순히 typedef을 사용하여 타입을 재정의할 경우
얻을 수 있는 이점이 없다고 얘기한다. 이어서 사용해야할 때를 아래와
같이 설명한다.

 (a) totally opaque objects (where the typedef is actively used to **hide**
     what the object is).

     Example: ``pte_t`` etc. opaque objects that you can only access using
     the proper accessor functions.

     .. note::

       Opaqueness and ``accessor functions`` are not good in themselves.
       The reason we have them for things like pte_t etc. is that there
       really is absolutely **zero** portably accessible information there.

 (b) Clear integer types, where the abstraction **helps** avoid confusion
     whether it is ``int`` or ``long``.

     u8/u16/u32 are perfectly fine typedefs, although they fit into
     category (d) better than here.

     .. note::

       Again - there needs to be a **reason** for this. If something is
       ``unsigned long``, then there's no reason to do

	typedef unsigned long myflags_t;

     but if there is a clear reason for why it under certain circumstances
     might be an ``unsigned int`` and under other configurations might be
     ``unsigned long``, then by all means go ahead and use a typedef.

 (c) when you use sparse to literally create a **new** type for
     type-checking.

 (d) New types which are identical to standard C99 types, in certain
     exceptional circumstances.

     Although it would only take a short amount of time for the eyes and
     brain to become accustomed to the standard types like ``uint32_t``,
     some people object to their use anyway.

     Therefore, the Linux-specific ``u8/u16/u32/u64`` types and their
     signed equivalents which are identical to standard types are
     permitted -- although they are not mandatory in new code of your
     own.

     When editing existing code which already uses one or the other set
     of types, you should conform to the existing choices in that code.

 (e) Types safe for use in userspace.

     In certain structures which are visible to userspace, we cannot
     require C99 types and cannot use the ``u32`` form above. Thus, we
     use __u32 and similar types in all structures which are shared
     with userspace.

Maybe there are other cases too, but the rule should basically be to NEVER
EVER use a typedef unless you can clearly match one of those rules.

In general, a pointer, or a struct that has elements that can reasonably
be directly accessed should **never** be a typedef.
