---
title: "Little Endian vs. Big Endian"
date: 2020-01-27T22:27:06+09:00
categories:
- Computer Science
tags:
- big endian
- little endian
- endian
---

# 개요

빅 엔디안과 리틀 엔디안에 관해 업무에서 접할 수 있는 상황과 각각에 해당하는 포인터 연산 예제를 종합적으로 정리하도록 한다.

![Endian 비교](/img/endian_compare.png)

엔디안(Endianness)은 컴퓨터의 메모리와 같은 **1차원 공간에 여러 개의 연속된 대상을 배열하는 방법**을 뜻하며, 바이트를 배열하는 방법을 바이트 순서(Byte-order)라고 한다. **엔디안은 보통 큰 단위가 앞에 나오는 빅 엔디안(Big-Endian)과 작은 단위가 앞에 나오는 리틀 엔디안(Little-Endian)으로 나눌 수 있으며**, 두 경우에 속하지 않거나 둘 모두 지원하는 것을 미들 엔디안(Middle-Endian)이라 부른다.

- Big-Endian: 최상위 바이트(MSB)부터 차례로 저장하는 방식
(사람이 읽고 쓰는 방식과 비슷함)
- Little-Endian: 최하위 바이트(LSB)부터 차례로 저장하는 방식

# 예제

예를 들어, 메모리에 0x12345678을 대입한다고 했을 때, 빅 엔디안과 리틀 엔디안 각각 아래와 같이 저장된다.

![Byte order in memory](/img/byte_order_in_mem.png)

빅 엔디안은 사람이 숫자를 사용하는 것과 같이 큰 단위의 바이트가 앞에 오는 방법이고 리틀 엔디안은 반대로 작은 단위의 바이트가 앞에 오는 방법이다.

    #include <stdio.h>

    int main(void) {
    	unsigned long value = 0x12345678;
    	unsigned char* ptr = &value;

    	int i;

    	for (i = 0; i < 4; i++) {
    		fprintf(stdout, "value[%d] = 0x%x\n", i, *ptr++);
    	}

    	unsigned long long value2 = 0x12345678abcdefab;
    	ptr = &value2;
    	for (i = 0; i < sizeof(value2); i++) {
    		fprintf(stdout, "value2[%d] = 0x%x\n", i, *ptr++);
    	}

    	return 0;
    }

위의 코드를 컴파일하여 Mac OS 환경에서 실행하면 아래와 같은 결과를 얻을 수 있다.

    ~/Workspaces/study/languages/modernc/endian $ ./endian
    value[0] = 0x78
    value[1] = 0x56
    value[2] = 0x34
    value[3] = 0x12
    value2[0] = 0xab
    value2[1] = 0xef
    value2[2] = 0xcd
    value2[3] = 0xab
    value2[4] = 0x78
    value2[5] = 0x56
    value2[6] = 0x34
    value2[7] = 0x12

0x12345678에서 MSB는 0x12, LSB는 0x78이며, LSB가 처음 나오는 것으로 보아 리틀 엔디안 방식으로 `Byte-ordering`을 하고 있는 것을 알 수 있다. `unsigned long long`의 경우로 확인할 수 있듯이 4바이트나 8바이트 단위로 byte-ordering 되는 것이 아니라 해당 데이터 타입에 따라 달라지는 것을 알 수 있다.

# 장/단점

## 가독성

Big-Endian은 소프트웨어의 디버그를 편하게 해주는 경향이 있다. 사람이 숫자를 읽고 쓰는 방법과 같기 때문에 디버깅 과정에서 메모리의 값을 보기 편하다. 예를 들어, ***0x59654148*을 Big-Endian으로 표현하면 *0x59, 0x65, 0x41, 0x48* 등으로 메모리에 순서대로 표현**된다.

반대로 Little-Endian은 메모리에 저장된 값의 하위 바이트들만 사용할 때 별도의 계산이 필요 없다는 장점이 있다. 예를 들어, 32비트 숫자인 0x2A는 리틀 엔디언으로 표현하면 2A 00 00 00이 되는데, 이 표현에서 앞의 두 바이트 또는 한 바이트만 떼어내면 하위 16비트 또는 8비트를 바로 얻을 수 있다. 반면 32비트 빅 엔디안 환경에서는 하위 16비트나 8비트 값을 얻기 위해 변수 주소에 2바이트 또는 3바이트를 더해야 한다.

# 커널 내 인터페이스

커널은 `byte order` 에 대한 의존성을 해결하기 위해 `Type Identifier`, `Conversion Macro` 등을 제공하고 있다. `include/uapi/linux/types.h` 헤더 파일 내에서는 아래와 같이 엔디안 별로 타입들이 정의되어 있는 것을 알 수 있다. 여기서 uapi 디렉토리는 커널의 userspace API를 포함하고 있다.
(참고. [https://stackoverflow.com/questions/18858190/whats-in-include-uapi-of-kernel-source-project](https://stackoverflow.com/questions/18858190/whats-in-include-uapi-of-kernel-source-project))

## 타입 정의

    /*
     * Below are truly Linux-specific types that should never collide with
     * any application/library that wants linux/types.h.
     */

    #ifdef __CHECKER__
    #define __bitwise__ __attribute__((bitwise))
    #else
    #define __bitwise__
    #endif
    #define __bitwise __bitwise__

    typedef __u16 __bitwise __le16;
    typedef __u16 __bitwise __be16;
    typedef __u32 __bitwise __le32;
    typedef __u32 __bitwise __be32;
    typedef __u64 __bitwise __le64;
    typedef __u64 __bitwise __be64;

    typedef __u16 __bitwise __sum16;
    typedef __u32 __bitwise __wsum;

bitwise 속성(단순히 정수로써 사용되는 것을 제한하는데 사용)으로 정의되어 있는 Type Identifiers 들이다. bitwise 속성은 sparse 유틸리티(static analyzer)가 변수에 대한 연산을 수행하기 전에 로컬 프로세서로 변환될 수 있도록 보장한다.

## Byte Order 알아내기

아래와 같이 간단한 user-space 프로그램을 작성하여 현재 시스템의 바이트 오더를 알아낼 수 있다.

    union {
        int i;
        char c[sizeof(int)];
    } foo;

    main() {
        foo.i = 1;
        if (foo.c[0] == 1)
            printf("Little endian\n");
        else
            printf("Big endian\n");
    }

다음에 소개되는 매크로는 변환 후의 값들을 반환한다.

    #include <linux/kernel.h>

    __u16	le16_to_cpu(const __le16);
    __u32	le32_to_cpu(const __le32);
    __u64	le64_to_cpu(const __le64);

    __le16	cpu_to_le16(const __u16);
    __le32	cpu_to_le32(const __u32);
    __le64	cpu_to_le64(const __u64);

    __u16	be16_to_cpu(const __be16);
    __u32	be32_to_cpu(const __be32);
    __u64	be64_to_cpu(const __be64);

    __be16	cpu_to_be16(const __u16);
    __be32	cpu_to_be32(const __u32);
    __be64	cpu_to_be64(const __u64);

포인터에 대한 변환은 p를 붙여서 아래와 같이 사용하며, 현재 사용 중인 프로세서 엔디안 환경에 맞게 변환해주는 매크로도 아래와 같이 제공하고 있다.

    #include <linux/kernel.h>

    void le16_to_cpus(__u16 *);
    void le32_to_cpus(__u32 *);
    void le64_to_cpus(__u64 *);

    void cpu_to_le16s(__u16 *);
    void cpu_to_le32s(__u32 *);
    void cpu_to_le64s(__u64 *);

    void be16_to_cpus(__u16 *);
    void be32_to_cpus(__u32 *);
    void be64_to_cpus(__u64 *);

    void cpu_to_be16s(__u16 *);
    void cpu_to_be32s(__u32 *);
    void cpu_to_be64s(__u64 *);

    __u16	le16_to_cpup(const __le16 *);
    __u32	le32_to_cpup(const __le32 *);
    __u64	le64_to_cpup(const __le64 *);

    __le16	cpu_to_le16p(const __u16 *);
    __le32	cpu_to_le32p(const __u32 *);
    __le64	cpu_to_le64p(const __u64 *);

    __u16	be16_to_cpup(const __be16 *);
    __u32	be32_to_cpup(const __be32 *);
    __u64	be64_to_cpup(const __be64 *);

    __be16	cpu_to_be16p(const __u16 *);
    __be32	cpu_to_be32p(const __u32 *);
    __be64	cpu_to_be64p(const __u64 *);

# 출처

- [http://www.bruceblinn.com/linuxinfo/ByteOrder.html](http://www.bruceblinn.com/linuxinfo/ByteOrder.html)
- [https://stackoverflow.com/questions/18858190/whats-in-include-uapi-of-kernel-source-project](https://stackoverflow.com/questions/18858190/whats-in-include-uapi-of-kernel-source-project)
