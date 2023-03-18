---
title: "커널에서의 Object-Oriented Design Pattern"
date: 2020-07-25T16:25:23+09:00
toc: false
tags:
- kernel
categories:
- linux
- design pattern
- oop
---

# 개요

현업에서 BSP 코드를 수정하다가 문득 든 생각은 '왜 객체 지향의 디자인
패턴을 적용하지 않는 걸까?' 라는 것이다. 그러한 디자인 패턴은 이미
오래 전부터 적용되어 왔지만 BSP에 포함된 솔루션 코드로서 추가되는
코드에는 그러한 디자인 패턴이 보이지 않는다.

Java나 C++, 그리고 완전하지는 않지만 `prototype`을 이용한
Javascript에서도 객체 지향적인 디자인 패턴이 적용되어 있다. 그렇다면,
C와 어셈블리어로 짜여진 커널에서는 이러한 디자인 패턴이 어떻게
적용되어 있을까. 여기에 대한 좋은 참고 자료로서 LWN의 한 기사를 찾을
수 있었다.

- https://lwn.net/Articles/446317/

학부 시절부터 오랫동안 들어온 객체의 정의는 `state`와
`behavior`이다. 이들은 각각 클래스의 멤버 변수와 메서드 형태로
구현되는데, 이러한 디자인 패턴 자체는 C를 이용해서도 표현이
가능하다. 멤버와 메서드는 각각 구조체 멤버와 `vtable(virtual function
table)` 형태로 표현될 수 있다. 그리고 데이터 상속의 개념으로서
`union`과 `void*`, `embedded structure` 등의 기법을 이용한다.

이 포스팅에서는 커널 코드에서 활용하는 객체지향 디자인 패턴의 기본적인
개념만을 언급한다. 좀 더 자세한 내용이나 실제 코드는 참고자료로 활용한
링크와 커널 코드를 살펴보자.

# 메서드

일반적으로 메서드를 생각하면, C에서 함수 포인터를 구조체에 정의하는
것을 떠올린다. 하지만 커널에서는 직접적으로 구조체 안에 함수 포인터를
사용하는 대신에 `vtable`을 만들어 `_ops` 으로 명명한 별도의 함수
테이블을 사용한다. 예를 들어, media framework로 유명한 `V4L2`를
이용하는 `videobuf2`를 살펴보자. 영상 프레임을 관리하는 큐에서 메모리
관리에 관련된 메서드는 아래와 같이 정의하여 사용한다.

``` c++
struct vb2_queue {
	unsigned int			type;
	unsigned int			io_modes;
	struct device			*dev;
	unsigned long			dma_attrs;

	const struct vb2_ops		*ops;
	const struct vb2_mem_ops	*mem_ops;

	...
```

그리고 `vb2_queue`에서 메서드 dispatch를 위해서 사용하는 메모리 관련
메서드는 아래와 같이 정의한다.

``` c++
struct vb2_mem_ops {
    void		*(*alloc)(struct device *dev, unsigned long attrs,
				  unsigned long size,
				  enum dma_data_direction dma_dir,
				  gfp_t gfp_flags);
    void		(*put)(void *buf_priv);
    struct dma_buf *(*get_dmabuf)(void *buf_priv, unsigned long flags);

    void		*(*get_userptr)(struct device *dev, unsigned long vaddr,
					unsigned long size,
					enum dma_data_direction dma_dir);
    void		(*put_userptr)(void *buf_priv);

    void		(*prepare)(void *buf_priv);
    void		(*finish)(void *buf_priv);

    void		*(*attach_dmabuf)(struct device *dev,
					  struct dma_buf *dbuf,
					  unsigned long size,
					  enum dma_data_direction dma_dir);
    void		(*detach_dmabuf)(void *buf_priv);
    int		(*map_dmabuf)(void *buf_priv);
    void		(*unmap_dmabuf)(void *buf_priv);

    void		*(*vaddr)(void *buf_priv);
    void		*(*cookie)(void *buf_priv);

    unsigned int	(*num_users)(void *buf_priv);

    int		(*mmap)(void *buf_priv, struct vm_area_struct *vma);
};

```

`virtual function table`을 사용할 경우 객체별로 사용할 수 있는
메서드들에 대한 인터페이스만 정의하고 실제 메서드에 대한 내용은 별도로
구현하여 사용할 수 있다. 즉, 클래스로 정의된 메서드 내용은 같지만 구현
내용은 객체마다 서로 다르게 할 수 있다는 장점이 있다.

그리고 `vtable`은 메서드에 대한 다중상속을 가능하게 하는데,
`closure`와 같은 다른 언어에서 `mixin`이라 표현하는 것처럼 응용할 수
있다. 서로 다른 객체에 대해 같은 메서드를 사용할 수 있도록 하는
방법이다.

# 데이터 상속

예전부터 데이터 상속은 여러 형태로 존재해왔는데, 여기서는 아래 세 가지
형태의 데이터 상속을 다루도록 한다.

- `union`을 이용한 데이터 상속
- `void*`를 이용한 데이터 상속
- 상속하고자 하는 데이터 직접 내포

## union을 이용한 데이터 상속

`struct inode`를 살펴보면 아래와 같은 코드를 살펴볼 수 있다.

```c++
 union {
               struct minix_inode_info minix_i;
               struct ext_inode_info ext_i;
               struct msdos_inode_info msdos_i;
       } u;
```

`inode` 안에서 `union`을 이용하여 노드에 대한 정보를 관리한다고 했을
때, 해당 `inode` 클래스는 상기 세 가지 중 하나에 대한 데이터를
상속하게 된다. 이는 직관적으로 코드를 이해할 수 있다는 장점이 있지만,
`union`을 사용하는 까닭에 padding을 위해 필요한 메모리 낭비로 이어질
수 있다.

## void* 이용한 데이터 상속

커널에 정의된 프레임워크를 이용하다 보면 종종 `void* private;` 으로
정의된 것이 구조체 안에 정의되어 있는 것을 알 수 있다. 위에서
`union`을 사용한 것과 달리 `void*` 사용하게 되면 불필요한 메모리는
줄일 수 있고 데이터 상속에 대한 유연성을 갖출 수 있지만 **실제로 어떤
데이터를 사용해야 하는가?**에 대한 질문에 직관적인 해석을 가져다 주지
못한다. 여전히 V4L 프레임워크와 같이 몇 군데에서 `void* private;`
형태로 사용되고 있지만 문서화와 쉽게 코드를 파악할 수 있는 구조가
아니라면, 이러한 포인터 형태는 지양되어야 한다.

## embedded structure

직접적으로 필요한 데이터들을 구조체 안에 멤버 변수로 정의하고,
`container_of` 매크로를 통해 부모 객체에 접근하도록 구현하는
방법이다. `void*` 에 비해 유연성은 떨어지지만 명시적으로 어떤 데이터를
상속하는지 나타낼 수 있고 매크로를 통해 부모에 정의되어 있는 함수
테이블을 이용하는 등 객체 지향 패턴을 적용하는데 무리가 없다. 여러
파일시스템의 코드를 살펴보면 아래와 같이 기본적인 `inode`에 대한
데이터 자체를 아래와 같이 내포한 형태로 사용하는 것을 알 수 있다.

``` c++
/* in memory btrfs inode */
struct btrfs_inode {
    /* which subvolume this inode belongs to */
    struct btrfs_root *root;

    /* key used to find this inode on disk.  This is used by the code
     * to read in roots of subvolumes
     */
    struct btrfs_key location;

    ...

    struct inode vfs_inode;
};
```

# 결론

객체지향 패턴을 적용하는 것은 중요하지만 만능은 아니다. 모든 곳에
이러한 객체 지향 디자인 패턴을 적용해야 하는 것은 잘못된 것이고 오히려
분석을 어렵게 만들 수도 있다. 디자인 패턴은 어디까지나 디자인 패턴일
뿐. 언어 때문에 특정 디자인 패턴을 적용할 수 없다는 얘기도 반은 맞고
반은 틀렸다. 커널에서 사용되는 `kref` 형태의 reference count 또한 특정
언어에 국한된 설계 패턴이 아니다. 타겟과 개발 환경에 따라 필요성과
효율성이 달라지는 것일 뿐 정답은 없다.
