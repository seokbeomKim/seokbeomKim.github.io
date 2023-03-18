---
title: "Stack Protector와 디버깅 이야기"
date: 2022-02-03T15:00:45+09:00
categories:
- Computer Science
tags:
- ssp
- stack
- canary
---

## Stack Protector, 넌 뭐하는 놈이냐?

현업에서 커널의 `CONFIG_STACK_PROTECTOR` 를 활성화하면 커널 부트가 안된다는 이슈가
보고되었다. Trace32 로 callstack을 살펴보니 내 파트에서 맡고 있는 디바이스 드라이버 코드 때문에
Stack Overflow가 발생하여 부트가 안되고 있었다. 문제의 지점은 사수가 발견하고 파트장의 수정으로 마무리되었다.

하지만 이슈가 마무리 되고 Stack Protector 가 어떤 원리로 동작하는지 궁금했고 설 연휴를
맞아 자세하게 정리할 수 있었다. 그 과정에서 우분투에 잘못된 버그 리포트 티켓을
만들어내긴 했지만 말이다.

Stack Protection은 GCC의 `-fstack-protector, -fstack-protector-all, -fstack-protector-strong`
옵션을 통해 활성화할 수 있고 `-fno-stack-protector` 옵션으로 비활성화 할 수 있다.

## 스택 레이아웃 살펴보기
### 비활성화 시의 레이아웃
먼저, Stack Protector를 비활성화/활성화 되었을 때의 각각 콜스택이 어떻게 되는지 살펴보자.

먼저, 아래와 같이 간단한 코드를 준비하였다.

```c
void mul(int a)
{
        a = a * 2;
}

void add(int a, int b, int c, int d)
{
        int j = a + 1;
        int e = b + 2;
        int f = c + 3;
        int g = d + 4;
        mul(j + e + f + g);
}

int main()
{
        int a = 0;
        int b = 1;
        int c = 2;
        int d = 3;
        add(a, b, c, d);

        return a;
}
```

호출 전/후로 ARM64 아키텍처에서의 Calling Convention을 확인하기 편하도록 최대한 코드를
할당 중심으로 작성하였다. 위 코드를 아래의 명령어로 컴파일한 후 다시 어셈블리로 바꿔주자.

```sh
$ aarch64-linux-gnu-gcc callstack.c     \
        -fno-stack-protector            \
        -fno-asynchronous-unwind-tables \
        -fno-exceptions                 \
        -fno-rtti -fverbose-asm         \
        -o callstack.o

$ aarch64-linux-gnu-objdump -dS callstack.o > callstack.disassemble
```

위와 같이 오브젝트 파일을 만들었다가 다시 dump 하는 이유는 불필요한 어셈블리 레이블을
없애기 위해서다. 실제로 gcc의 -S 옵션을 사용하여 단순하게 어셈블리 코드를 만들어내면 원하는
어셈 코드를 얻기 힘들다. 이제 얻어낸 어셈블리 코드를 살펴보자.

```
0000000000000714 <mul>:
 714:	d10043ff 	sub	sp, sp, #0x10
 718:	b9000fe0 	str	w0, [sp, #12]
 71c:	b9400fe0 	ldr	w0, [sp, #12]
 720:	531f7800 	lsl	w0, w0, #1
 724:	b9000fe0 	str	w0, [sp, #12]
 728:	d503201f 	nop
 72c:	910043ff 	add	sp, sp, #0x10
 730:	d65f03c0 	ret

0000000000000734 <add>:
 734:	a9bd7bfd 	stp	x29, x30, [sp, #-48]!
 738:	910003fd 	mov	x29, sp
 73c:	b9001fe0 	str	w0, [sp, #28]
 740:	b9001be1 	str	w1, [sp, #24]
 744:	b90017e2 	str	w2, [sp, #20]
 748:	b90013e3 	str	w3, [sp, #16]
 74c:	b9401fe0 	ldr	w0, [sp, #28]
 750:	11000400 	add	w0, w0, #0x1
 754:	b9002fe0 	str	w0, [sp, #44]
 758:	b9401be0 	ldr	w0, [sp, #24]
 75c:	11000800 	add	w0, w0, #0x2
 760:	b9002be0 	str	w0, [sp, #40]
 764:	b94017e0 	ldr	w0, [sp, #20]
 768:	11000c00 	add	w0, w0, #0x3
 76c:	b90027e0 	str	w0, [sp, #36]
 770:	b94013e0 	ldr	w0, [sp, #16]
 774:	11001000 	add	w0, w0, #0x4
 778:	b90023e0 	str	w0, [sp, #32]
 77c:	b9402fe1 	ldr	w1, [sp, #44]
 780:	b9402be0 	ldr	w0, [sp, #40]
 784:	0b000021 	add	w1, w1, w0
 788:	b94027e0 	ldr	w0, [sp, #36]
 78c:	0b000021 	add	w1, w1, w0
 790:	b94023e0 	ldr	w0, [sp, #32]
 794:	0b000020 	add	w0, w1, w0
 798:	97ffffdf 	bl	714 <mul>
 79c:	d503201f 	nop
 7a0:	a8c37bfd 	ldp	x29, x30, [sp], #48
 7a4:	d65f03c0 	ret

00000000000007a8 <main>:
 7a8:	a9be7bfd 	stp	x29, x30, [sp, #-32]!
 7ac:	910003fd 	mov	x29, sp
 7b0:	b9001fff 	str	wzr, [sp, #28]
 7b4:	52800020 	mov	w0, #0x1                   	// #1
 7b8:	b9001be0 	str	w0, [sp, #24]
 7bc:	52800040 	mov	w0, #0x2                   	// #2
 7c0:	b90017e0 	str	w0, [sp, #20]
 7c4:	52800060 	mov	w0, #0x3                   	// #3
 7c8:	b90013e0 	str	w0, [sp, #16]
 7cc:	b94013e3 	ldr	w3, [sp, #16]
 7d0:	b94017e2 	ldr	w2, [sp, #20]
 7d4:	b9401be1 	ldr	w1, [sp, #24]
 7d8:	b9401fe0 	ldr	w0, [sp, #28]
 7dc:	97ffffd6 	bl	734 <add>
 7e0:	b9401fe0 	ldr	w0, [sp, #28]
 7e4:	a8c27bfd 	ldp	x29, x30, [sp], #32
 7e8:	d65f03c0 	ret
```

어셈블리 코드를 살펴보면 main, add, mul 함수가 호출될 때마다 첫번째 라인에서 x29/x30 값을
sp (스택 포인터)에 저장하고 Stack Frame을 확보하는 것을 알 수 있다. x29는 Frame Pointer,
x30은 Link Register로서 사용되며 각각 스택 프레임의 base, Return Address를 갖고 있다고
생각하면 된다. add 함수가 mul 함수에서 각각 stack frame을 확보하는 어셈블리 명령어가
다르게 나와있다. add 함수를 먼저 살펴보면 아래와 같다.

```
stp     x29, x30, [sp, #-48]!
```

이는 x29, x30 값을 [sp]에 저장(sp가 갖고 있는 메모리 주소에)한 다음 sp를 -48 오프셋만큼
이동하라는 뜻이다. 이 때, 스택 할당은 메모리 반대 방향으로 확보되는 점에 주목하자. mul 함수는
별도의 백업 없이 곧바로 스택 프레임을 확보하는 것을 볼 수 있다.

계속해서 add 함수를 살펴보면 스택 프레임을 확보한 후 int d, e, f에 해당하는 지역 변수들을
스택에 저장하는 것을 알 수 있다. x29는 stack frame pointer, x30은 return address를
저장하고 있다.

![Stack Layout without Stack Protector](/img/stack-protector_figure_1.png)

### 활성화 시의 레이아웃

그렇다면 stack protector가 활성화된 메모리 레이아웃은 어떻게 될까? 이번에는
-fstack-protector-all 옵션을 이용하여 어셈블리 코드를 생성해주자.

```
000000000000086c <add>:
 86c:	a9bc7bfd 	stp	x29, x30, [sp, #-64]!
 870:	910003fd 	mov	x29, sp
 874:	b9001fe0 	str	w0, [sp, #28]
 878:	b9001be1 	str	w1, [sp, #24]
 87c:	b90017e2 	str	w2, [sp, #20]
 880:	b90013e3 	str	w3, [sp, #16]
 884:	90000080 	adrp	x0, 10000 <__FRAME_END__+0xf520>
 888:	f947f400 	ldr	x0, [x0, #4072]
 88c:	f9400001 	ldr	x1, [x0]
 890:	f9001fe1 	str	x1, [sp, #56]
 894:	d2800001 	mov	x1, #0x0                   	// #0
 898:	b9401fe0 	ldr	w0, [sp, #28]
 89c:	11000400 	add	w0, w0, #0x1
 8a0:	b9002be0 	str	w0, [sp, #40]
 8a4:	b9401be0 	ldr	w0, [sp, #24]
 8a8:	11000800 	add	w0, w0, #0x2
 8ac:	b9002fe0 	str	w0, [sp, #44]
 8b0:	b94017e0 	ldr	w0, [sp, #20]
 8b4:	11000c00 	add	w0, w0, #0x3
 8b8:	b90033e0 	str	w0, [sp, #48]
 8bc:	b94013e0 	ldr	w0, [sp, #16]
 8c0:	11001000 	add	w0, w0, #0x4
 8c4:	b90037e0 	str	w0, [sp, #52]
 8c8:	b9402be1 	ldr	w1, [sp, #40]
 8cc:	b9402fe0 	ldr	w0, [sp, #44]
 8d0:	0b000021 	add	w1, w1, w0
 8d4:	b94033e0 	ldr	w0, [sp, #48]
 8d8:	0b000021 	add	w1, w1, w0
 8dc:	b94037e0 	ldr	w0, [sp, #52]
 8e0:	0b000020 	add	w0, w1, w0
 8e4:	97ffffcc 	bl	814 <mul>
 8e8:	d503201f 	nop
 8ec:	90000080 	adrp	x0, 10000 <__FRAME_END__+0xf520>
 8f0:	f947f400 	ldr	x0, [x0, #4072]
 8f4:	f9401fe2 	ldr	x2, [sp, #56]
 8f8:	f9400001 	ldr	x1, [x0]
 8fc:	eb010042 	subs	x2, x2, x1
 900:	d2800001 	mov	x1, #0x0                   	// #0
 904:	54000040 	b.eq	90c <add+0xa0>  // b.none
 908:	97ffff66 	bl	6a0 <__stack_chk_fail@plt>
 90c:	a8c47bfd 	ldp	x29, x30, [sp], #64
 910:	d65f03c0 	ret
```

보기에도 이전에 살펴봤던 add 함수보다 훨씬 코드가 길어졌다. 여기서 중요한 건 함수 초기에
스택 포인터를 움직인 후 canary 영역을 스택에 저장하는 부분이다.

```
 884:	90000080 	adrp	x0, 10000 <__FRAME_END__+0xf520>
 888:	f947f400 	ldr	x0, [x0, #4072]
 88c:	f9400001 	ldr	x1, [x0]
 890:	f9001fe1 	str	x1, [sp, #56]
 ...
 908:	97ffff66 	bl	6a0 <__stack_chk_fail@plt>
```

![Stack Layout without Stack Protector](/img/stack-protector_figure_2.png)

Stack Frame Pointer와 Link Register 정보를 스택 하위에 두고 일반적으로는 곧바로
지역변수들이 위치하지만 Stack Protector 를 활성화하면 이 영역이 canary 영역으로 채워지는
것을 알 수 있다.

## Stack Smashing 에러가 안난다? Canary Boundary

ARM Reference 문서에 나와있는 예제
(https://developer.arm.com/documentation/101754/0616/armclang-Reference/armclang-Command-line-Options/-fstack-protector---fstack-protector-all---fstack-protector-strong---fno-stack-protector)
로 직접 확인해보려 했지만 의도된대로 에러가 발생하지 않았다. 이에 직접 GDB 를 이용하여 디버깅을
해보니 아래와 같이 fs:0x28, 즉 canary value의 하위 8비트가 0으로 초기화되어 있었다.

![Stack Layout without Stack Protector](/img/stack-protector_figure_3.png)

fs, gs 레지스터는 특별한 운영체제의 자료구조에 접근하기 위한 것이다. 특히, FS:0x28은
리눅스에서 stack-guard 값을 저장하고 stack-guard check 루틴에서 사용된다.
(https://stackoverflow.com/questions/10325713/why-does-this-memory-address-fs0x28-fs0x28-have-a-random-value)
그런데 fs:0x28 값이 처음부터 하위 1바이트가 초기화되어 있다는 것은 커널 쪽 코드에 의한 것이라고
생각하고 살펴보니, 커널 include/linux/random.h 파일에 아래의 코드가 있었다.

```c
/*
 * On 64-bit architectures, protect against non-terminated C string overflows
 * by zeroing out the first byte of the canary; this leaves 56 bits of entropy.
 */
#ifdef CONFIG_64BIT
# ifdef __LITTLE_ENDIAN
#  define CANARY_MASK 0xffffffffffffff00UL
# else /* big endian, 64 bits: */
#  define CANARY_MASK 0x00ffffffffffffffUL
# endif
#else /* 32 bits: */
# define CANARY_MASK 0xffffffffUL
#endif

static inline unsigned long get_random_canary(void)
{
	unsigned long val = get_random_long();

	return val & CANARY_MASK;
}
```

처음에는 굳이 이렇게 NULL을 처리해야 하나 싶었는데 블라인드를 통해 알게된 사실은 canary
value를 바로 출력하지 못하도록 NULL 문자를 이용해 boundary를 생성하기 위한 용도라는 것을
알게됐다. 이로써 stack protector가 스택에서 어떻게 위치하는지, 그리고 왜 ARM 레퍼런스 문서에
있는 예제가 동작을 하지 않는지, canary boundary 값이 왜 NULL로 되어있는지 등을 알 수 있었다.

## 참고 자료

- [FS/GS 레지스터 in Stackoverflow](https://stackoverflow.com/questions/10325713/why-does-this-memory-address-fs0x28-fs0x28-have-a-random-value)
- [stp 레지스터 사용 예](https://wolchok.org/posts/how-to-read-arm64-assembly-language/)
- [ARM 어셈블리 강좌 자료 - Function Calls](https://www.cs.princeton.edu/courses/archive/spr19/cos217/lectures/15_AssemblyFunctions.pdf)
- [ARM64 스택 분석 자료](https://thinkingeek.com/2017/05/29/exploring-aarch64-assembler-chapter-8/)
- [GCC 어셈블리 strip 방법 #1](https://stackoverflow.com/questions/38552116/how-to-remove-noise-from-gcc-clang-assembly-output)
- [GCC 어셈블리 strip 방법 #2](https://stackoverflow.com/questions/2529185/what-are-cfi-directives-in-gnu-assembler-gas-used-for)