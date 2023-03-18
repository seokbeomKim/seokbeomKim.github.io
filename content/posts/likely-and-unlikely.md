---
title: "Likely and Unlikely"
date: 2020-02-13T23:27:51+09:00
categories:
- kernel
tags:
- likely
- unlikely
---

# 개요
예전에 관리하던 블로그에서 커널에서 사용하는 `likely`와 `unlikely` 에
대해서 정리한 포스팅이 있었다. 하지만 시간이 지나 커널 분석 책을 다시
보며 likely, unlikely를 보니 다시 헷갈리기 시작했다.

회사 업무에서 실행 시간을 줄이는 데에 중요도를 두고 있지만 그 방법에
대해서는 아직 다루지 못하고 있다. 솔루션이 안정화되고 전체적인 업무
내용이 파악되면 본 내용을 정리하면서 실행 시간을 감소할 방법으로
prediction을 이용하는 것을 건의해보고 진행해볼 수 있을 것 같다.

# likely(), unlikely()
함수의 이름 그대로, 자주 일어날 듯하거나 자주 일어나지 않을 듯한 것을
위한 매크로이다. 출처에는 아래와 같은 예제를 제공하고 있다.

``` c++
bvl = bvec_alloc(gfp_mask, nr_iovecs, &idx);
if (unlikely(!bvl)) {
	mempool_free(bio, bio_pool);
	bio = NULL;
	goto out;
}
```

특정 condition을 확인하는 용도로 사용하는데 위의 코드에서는
`bvec_alloc`으로 할당받고 bvl이 유효한 주소값이라면 메모리 해제를 하고
NULL로 변경하는 코드이다.

`include/linux/compiler.h` 파일에 정의되어 있는 매크로로서 branch
prediction 을 위한 용도로 사용된다. 즉, 결과값이 대부분 false로
예상된다면 `unlikely()`를, true로 예상된다면 `likely()`를 사용함으로서
컴파일러를 통한 분기 예측을 이용하여 성능 향상을 꾀할 수 있다.

각각의 정의를 살펴보면, 아래와 같이 되어 있다.

``` c++
#define likely(x)       __builtin_expect(!!(x), 1)
#define unlikely(x)     __builtin_expect(!!(x), 0)
```

# __built-in function
`__builtin_expect`를 사용하는 것은 컴파일러에게 분기 예측(branch
prediction) 정보를 제공하기 위한 것이다. 일반적으로 개발자들은 자신의
프로그램이 어떻게 수행되는지 알기 힘들기 때문에 '-fprofile-arcs'
옵션을 통해 프로파일을 피드백 받는 것을 선호한다. 하지만
애플리케이션에 따라서 이러한 옵션을 통해 프로파일링이 힘든 경우도
있다.

# 예제
아래의 예제를 통해 성능 향상이 어떻게 가능한지 살펴보자.

``` c++
#define likely(x)    __builtin_expect(!!(x), 1)
#define unlikely(x)  __builtin_expect(!!(x), 0)

int main(int argc, char *argv[]) {
	int a;

	a = atoi (argv[1]);

	if (unlikely (a == 2))
		a++;
	else
		a--;

	printf("%d\n", a);

	return 0;
}
```

위 예제를 컴파일 한 다음, objdump로 살펴보면 아래와 같이 main 부분을
발견할 수 있다.

``` bash
$ gcc -o unlikely unlikely.c
$ objdump -S unlikely


0000000000001149 <main>:
    1149:	55                   	push   %rbp
    114a:	48 89 e5             	mov    %rsp,%rbp
    114d:	48 83 ec 20          	sub    $0x20,%rsp
    1151:	89 7d ec             	mov    %edi,-0x14(%rbp)
    1154:	48 89 75 e0          	mov    %rsi,-0x20(%rbp)
    1158:	48 8b 45 e0          	mov    -0x20(%rbp),%rax
    115c:	48 83 c0 08          	add    $0x8,%rax
    1160:	48 8b 00             	mov    (%rax),%rax
    1163:	48 89 c7             	mov    %rax,%rdi
    1166:	b8 00 00 00 00       	mov    $0x0,%eax
    116b:	e8 d0 fe ff ff       	callq  1040 <atoi@plt>
    1170:	89 45 fc             	mov    %eax,-0x4(%rbp)
    1173:	83 7d fc 02          	cmpl   $0x2,-0x4(%rbp)
    1177:	0f 94 c0             	sete   %al
    117a:	0f b6 c0             	movzbl %al,%eax
    117d:	48 85 c0             	test   %rax,%rax
    1180:	74 06                	je     1188 <main+0x3f>
    1182:	83 45 fc 01          	addl   $0x1,-0x4(%rbp)
    1186:	eb 04                	jmp    118c <main+0x43>
    1188:	83 6d fc 01          	subl   $0x1,-0x4(%rbp)
    118c:	8b 45 fc             	mov    -0x4(%rbp),%eax
    118f:	89 c6                	mov    %eax,%esi
    1191:	48 8d 3d 6c 0e 00 00 	lea    0xe6c(%rip),%rdi        # 2004 <_IO_stdin_used+0x4>
    1198:	b8 00 00 00 00       	mov    $0x0,%eax
    119d:	e8 8e fe ff ff       	callq  1030 <printf@plt>
    11a2:	b8 00 00 00 00       	mov    $0x0,%eax
    11a7:	c9                   	leaveq
    11a8:	c3                   	retq
    11a9:	0f 1f 80 00 00 00 00 	nopl   0x0(%rax)
```

`cmpl %0x2, -0x4(%rbp)` 에서 보듯 2와 같을 경우에 jump 명령어를
수행하고 같지 않을 경우에는 계속해서 명령어를 순차 진행한다. je
명령어를 실행하지 않으니 pipeline flush가 일어나지 않아 branch
prediction을 하지 않았을 때보다 성능 향상을 꾀할 수 있다.

만약, `likely()`를 하게 되면 어떨까? 아마 반대로 명령어가 실행될
것이다. 즉, 프로그래머가 예상하는 시나리오로 분기 예측을 하여 최대한
jump 명령어를 수행하지 않도록 하는 기법이다.

# 출처
- https://woodz.tistory.com/67
