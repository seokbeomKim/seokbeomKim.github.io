---
title: "Major와 Minor Numbers"
date: 2019-05-31T18:37:25+09:00
categories:
- O/S
- Linux
- kernel
tags:
- minor number
- major number
---

세마포어를 이용한 모듈 프로그래밍을 하던 중 `Major, Minor` 라는 개념이
등장하였다. 인터넷으로 찾은 커널 모듈 소스가 구버전 커널을 기준으로 한
까닭에, 커널 코드가 어떻게 변경되어 갔는지 히스토리를 삽질해 볼 수
있는 아주 좋은 기회다.

캐릭터 디바이스는 `/dev` 디렉토리에서 쉽게 확인할 수 있는데 파일의
속성에서 각 장치에 대한 속성은 맨 앞 문자를 통해 판단할 수 있다. 예를
들어, 'c'를 포함하고 있다면 캐릭터 디바이스(character devices)를 위한
특수 파일로, 'b'를 포함하고 있다면 블록 디바이스(block devices)로
식별할 수 있다. 아래와 같이 `ls` 명령어를 사용하면 각 디바이스 파일에
번호가 할당되어 있는 것을 알 수 있다.

``` shell 
drwxr-xr-x   2 root    root           60 May 31 23:18 vfio
crw-------   1 root    root    10,    63 May 31 23:18 vga_arbiter
crw-------   1 root    root    10,   137 May 31 23:18 vhci
crw-rw----+  1 root    kvm     10,   238 May 31 23:18 vhost-net
crw-------   1 root    root    10,   241 May 31 23:18 vhost-vsock
crw-rw----+  1 root    video   81,     0 May 31 23:18 video0
crw-rw----+  1 root    video   81,     1 May 31 23:18 video1
crw-------   1 root    root    10,   130 May 31 23:18 watchdog
crw-------   1 root    root   246,     0 May 31 23:18 watchdog0
crw-rw-rw-   1 root    root     1,     5 May 31 23:18 zero
```

이 때, `major number`는 특정 디바이스에 할당된 드라이버를
식별한다. 예를 들어, `/dev/zero`는 드라이버 1이 관리하고
`/dev/watchdog0`은 드라이버 246이 관리한다. `minor number`는
드라이버가 맡고 있는 장치들을 분류하기 위한 것으로 아래와 같이 같은
`major number`를 가지고 있는 장치들을 분류할 때 사용한다.

``` shell
➜  ~ ls -l /dev | egrep '^c.*.(\s)1,'
crw-rw-rw-  1 root    root     1,     7 May 31 23:18 full
crw-r--r--  1 root    root     1,    11 May 31 23:18 kmsg
crw-r-----  1 root    kmem     1,     1 May 31 23:18 mem
crw-rw-rw-  1 root    root     1,     3 May 31 23:18 null
crw-r-----  1 root    kmem     1,     4 May 31 23:18 port
crw-rw-rw-  1 root    root     1,     8 May 31 23:18 random
crw-rw-rw-  1 root    root     1,     9 May 31 23:18 urandom
crw-rw-rw-  1 root    root     1,     5 May 31 23:18 zero
```

버전 2.4 커널에서 `devfs(device file system)`라는 새 기능이
추가되었다. 만약 이 파일시스템 사용되면 디바이스 파일들을 그 전보다
훨씬 간단하게 관리할 수 있지만 호환성에 문제가 생긴다. 이에 대해서
자세히 알아보자.

`devfs`를 사용하지 않을 경우, `시스템에 드라이버를 새로 추가한다`는
의미는 새로운 `major number`를 할당한다는 의미와 같다. 그래서 아래와
같은 코드를 이용해 직접 그 숫자를 할당해줘야 한다.

``` c++
// return: success or failure(<0)
// major: major number being requested
// name: name of the device (which will appear in /proc/devices)
// fops: driver's entry point
int register_chrdev(unsigned int major, const char *name, struct file_operations *fops);
```

`Major Number`는 `small integer` 형태로서 캐릭터 드라이버 배열의
인덱스를 담당한다. 2.0 커널에서는 128개 디바이스에 대해, 2.2와
2.4에서는 256개 디바이스에 대한 인덱스를 가질 수 있으며 `Minor
Number`의 경우 8비트를 가져 마찬가지로 256개 디바이스에 대한 인덱스를
가질 수 있다. 하지만 `Minor Number`는 위 함수에서 특별히 인자로 넘기지
않는데 이는 드라이버에서만 제한적으로 사용되는 숫자이기 때문에 그렇다.

드라이버를 커널 테이블에 등록하면 주어진 `major number`를
할당한다. 이후부터는 캐릭터 디바이스에 대한 파일 연산을 할 때마다 등록
시에 정의했던 `file_operations` 구조체의 각 함수들을 이용하게
된다. 하지만 코드가 아닌 실제 명령어를 통해 이러한 등록 과정을 아주
간단히 할 수가 있는데 그것이 바로 `mknod` 명령어이다.

``` shell
$ mknod /dev/scull0 c 254 0
$ rm /dev/scull0
```

위처럼 major number가 254, minor number가 0인 캐릭터 디바이스(c)를
생성하고 해당 디바이스를 삭제할 수 있다. 하지만 이렇게 정적으로
디바이스를 관리하는 인덱스 번호를 할당할 필요가 있을까?

# Dynamic Allocation of Major Numbers
몇몇 주요 장치들에 대한 인덱스 숫자는 정적으로 할당된다. 이러한
장치들에 대한 정보는 `Documentation/admin-guide/devices.txt`에서 찾을
수 있다. (책에는 `Documentation/devices.txt`라고 되어 있으나 커널
버전이 업되면서 경로가 바뀌었다.)

정적으로 `Major Number`를 할당하면 공식 커널 트리에 포함되어 유용하게
사용되는 경우에만 할당해야 하며, 그렇지 않으면 반드시 동적으로
할당하는 방법을 사용해야 한다. 하지만 동적으로 `Major Number`를
할당하는 방법의 단점은 디바이스 노드를 생성할 수 없다는 것이다. 항상
같은 번호를 할당받을 수 없기 때문인데 이 말은 즉슨,
`loading-on-demand` 방식을 사용할 수 없다는 말과 같다. 하지만 이러한
특징은 일반적인 사용에 있어서 크게 문제가 되지는 않는다. 앞서 설명했던
것처럼 `/proc/devices`의 정보를 사용하면 되기 때문이다.

동적으로 생성하는 방법은 아래와 같은 코드를 이용하면 된다. 이 때,
`scull_major` 값을 0으로 주어지면 동적 할당을 사용한다는 의미이다.

``` c++
result = register_chrdev(scull_major, "scull", &scull_fops);
if (result < 0) {
    printk(KERN_WARNING "scull: can't get major %d\n", scull_major);
    return resul;t
}
if (scull_major == 0) scull_major = result; /* dynamic */

unregister_chrdev(scull_major, "scull");
```

이 때, 코드 마지막에 위치하는 `unregister_chrdev` 사용에 있어서
실패했을 경우를 염두에 두어야 한다. 등록 해제(unregister_chrdev)가
실패했을 때는 그 영향에 대해 주의해야 한다.`/proc/devices` 자체가
실패할 수 있는데 그 이유는 이미 해제된 장치에 대해 이름을 가리키는
포인터가 잘못될 수 있기 때문이다.

# kdev_t and  dev_t
본래 유닉스에서는 16비트 정수 형태로 `dev_t`안에 디바이스 번호를 담고
있었는데 오늘날에는 이것이 minor number의 최대치인 256보다 더 많은
인덱스 숫자를 한번에 요구하는 경우가 생기게 되었다. 하지만 하위
호환성을 위해서 `dev_t`자체의 구조를 변경하지는 못하고 있다.

리눅스에서는 이와 달리 `kdev_t`라는 약간 다른 타입을
사용한다. 블랙박스 형태로 설계되었기 때문에 사용자 애플리케이션은
`kdev_t`에 대해 완전히 알지 못하고 커널 함수들 또한 해당 자료구조의
내부를 정확히 알지 못한다. 때문에 커널 버전 변경에 따라 자료구조가
변경되더라도 디바이스 드라이버에서 해당 변경에 대해 별다른 변경 작업을
할 필요가 없도록 설계되었다. `kdev_t`를 이용하기 위해서는 직접 사용할
필요가 없고 아래와 같이 제공되는 함수 또는 매크로를 이용한다.

``` c++
// Extract the major number from a kdev_t structure.
#define MAJOR(dev)	((unsigned int) ((dev) >> MINORBITS))

// Extract the minor number.
#define MINOR(dev)	((unsigned int) ((dev) & MINORMASK))

// Create a kdev_t build from major and minor numbers
#define MKDEV(ma,mi)	(((ma) << MINORBITS) | (mi))
```

# 출처
- https://www.oreilly.com/library/view/linux-device-drivers/0596000081/ch03s02.html
