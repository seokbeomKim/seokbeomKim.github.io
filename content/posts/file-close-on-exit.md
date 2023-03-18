---
title: "프로세스 종료와 파일 디스크립터"
date: 2022-05-10T00:03:20+09:00
categories:
- kernel
tags:
- file descriptor
---

## 파일을 open 했는데 close를 안하면?

stdin(0), stdout(2), stderr(3) 이라는 정해진 공식과 함께 리다이렉션과 파이프의 개념만으로도 흥분하던 대학교 시절에 내가 알던 파일 디스크립터의 정의는 *태스크가 파일을 열면 얻게 되는 고유 id값* 이었다. 그리고 이러한 파일디스크립터는 항상 open 을 해주면 close 를 해줘야 한다고 배웠다. 그런데 막상 단순한 텍스트 파일을 open 한 뒤 프로세스 종료 전 close를 명시적으로 하지 않아도 이로 인한 오류는 발생하지 않는다. 그 전에는 단순하게 프로세스 종료 시에 파일 디스크립터도 함께 정리해주겠거니 하고 넘어갔던 내용이지만 본 글에서는 이 부분에 대해서 간단히(?) 살펴보고자 한다.

## strace 로 삽질 포인트 찾기

업무와는 관련이 없지만 간혹 코드에 open만 있는데도 불구하고 파일 디스크립터에 대한 에러가 발생하지 않는 불편한 코드들을 보면서 평소에 궁금했던 부분이라 잠깐 이 부분을 찾아보기로 했다. 먼저 아래와 같이 간단한 코드를 하나 작성한 뒤 컴파일해준다.

```c
// cat sysclose_test.c
#include <unistd.h>
#include <stdlib.h>
#include <syscall.h>
#include <fcntl.h>

int main(void)
{
        int fd;

        fd = open("test", O_RDWR);

        exit(1);
}
```

마지막 라인의 `exit(1)` 부분은 추가하지 않아도 인자만 다른 채로 동일한 시스템 콜이 호출된다. 이제 strace 를 통해 시스템콜이 어떻게 호출되는지 살펴보자.

```bash
$ strace ./sysclose_test
execve("./sysclose_test", ["./sysclose_test"], 0x7fff0fb6ea80 /* 40 vars */) = 0
mmap(0x7fcdffece000, 360448, PROT_READ, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x1bc000) = 0x7fcdffece000
mmap(0x7fcdfff27000, 24576, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x214000) = 0x7fcdfff27000
mmap(0x7fcdfff2d000, 52816, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_ANONYMOUS, -1, 0) = 0x7fcdfff2d000
close(3)                                = 0
mmap(NULL, 8192, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7fcdffd10000
arch_prctl(ARCH_SET_FS, 0x7fcdfff3b5c0) = 0
set_tid_address(0x7fcdfff3b890)         = 375046
set_robust_list(0x7fcdfff3b8a0, 24)     = 0
mprotect(0x7fcdfff27000, 16384, PROT_READ) = 0
mprotect(0x55c5fce58000, 4096, PROT_READ) = 0
mprotect(0x7fcdfff81000, 8192, PROT_READ) = 0
prlimit64(0, RLIMIT_STACK, NULL, {rlim_cur=8192*1024, rlim_max=RLIM64_INFINITY}) = 0
munmap(0x7fcdfff3c000, 71131)           = 0
openat(AT_FDCWD, "test", O_RDWR)        = 3
exit_group(0)                           = ?
+++ exited with 0 +++
```

마지막으로 출력된 라인으로부터 `exit_group(0)` 시스템 콜이 호출된 것을 알 수 있다. 삽질 포인트를 찾았으니 이제 본격적으로 삽질할 준비는 되었다.

## do_exit -> exit_files

`exit_group(0)` 을 시작으로 함수콜을 따라가다보면 다음과 같은 호출 경로를 찾아낼 수 있다.

```
-> exit_group()
    +-> do_exit()
        +-> exit_files()
            +-> put_files_struct()
                +-> close_files()
```

핵심은 종료될 태스크의 파일 리스트를 얻은 뒤 NULL로 바꾸고, put_files_struct 에 리스트를 인자로 넘기면서 파일들을 close 하는 부분이다.
이 부분을 통해서 왜 굳이 명시적으로 close 를 하지 않아도 태스크 종료 시에 파일 디스크립터들이 정리되는지 알 수 있다.

```c
void exit_files(struct task_struct *tsk)
{
	struct files_struct * files = tsk->files;

	if (files) {
		io_uring_files_cancel(files);
		task_lock(tsk);
		tsk->files = NULL;
		task_unlock(tsk);
		put_files_struct(files);
	}
}

void put_files_struct(struct files_struct *files)
{
	if (atomic_dec_and_test(&files->count)) {
		struct fdtable *fdt = close_files(files);

		/* free the arrays if they are not embedded */
		if (fdt != &files->fdtab)
			__free_fdtable(fdt);
		kmem_cache_free(files_cachep, files);
	}
}

static struct fdtable *close_files(struct files_struct * files)
{
	/*
	 * It is safe to dereference the fd table without RCU or
	 * ->file_lock because this is the last reference to the
	 * files structure.
	 */
	struct fdtable *fdt = rcu_dereference_raw(files->fdt);
	unsigned int i, j = 0;

	for (;;) {
		unsigned long set;
		i = j * BITS_PER_LONG;
		if (i >= fdt->max_fds)
			break;
		set = fdt->open_fds[j++];
		while (set) {
			if (set & 1) {
				struct file * file = xchg(&fdt->fd[i], NULL);
				if (file) {
					filp_close(file, files);
					cond_resched();
				}
			}
			i++;
			set >>= 1;
		}
	}

	return fdt;
}
```

## 마치며

파일이 닫히는 것까지 커널 코드를 읽고 분석하는데 시간이 꽤 걸릴 것이라 생각했지만 생각보다 단계가 단순하여 금방 이해할 수 있었다.
한가지 중요한 것은, 본 글에서 분석한 내용이 코드 상에서 close()를 하지 않아도 된다는 의미는 아니라는 점이다. 리눅스에서는 디바이스 노드로써 디바이스를 컨트롤한다. 이 경우 open()과 close()를 명시적으로 사용하지 않으면 디바이스 초기화 시점을 코드로써 기술할 수 없게 되므로 문제가 발생할 가능성이 높아지기 때문에 주의해야 한다.