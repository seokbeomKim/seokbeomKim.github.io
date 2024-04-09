---
draft: true
title: "Vmlinux"
date: 2020-04-21T06:04:17+09:00
categories:
- kernel
tags:
- vmlinux
---

커널 패닉 정보를 바탕으로 패닉이 정확히 어디서 발생했는지를 알아내기 위해 vmlinux 파일을 이용하는 방법을 알게 되었다. `addr2line` 명령어를 이용하여 PC 또는 LR에 들어있던 주소를 이용하여 실행된 명령어가 코드상으로 어디에 위치했는지를 알아내는 것인데 어떤 이유로 디버깅이 가능한지 궁금했기에 이 포스팅에서는 addr2line을 이용한 커널패닉 분석 방법과 vmlinux에 관련된 파일 종류에 대해 간단히 언급하고자 한다.

## 커널 패닉 메시지 분석하기

출처로 명시된 페이지에서 기술되어 있듯 아래와 같은 커널 패닉 메시지가 나왔다고 가정했을 때 `addr2line` 명령어와 `vmlinux` 파일을 이용해 실행 위치를 알아낼 수 있다.

``` text
[    0.167728] BUG: unable to handle kernel NULL pointer dereference at 0000000000000050
[    0.167733] IP: [<ffffffff810b6fda>] task_tick_fair+0xea/0x9e0
[    0.167734] PGD 0
[    0.167736] Oops: 0000 [#1] SMP
[    0.167737] Modules linked in:
[    0.167739] CPU: 0 PID: 1 Comm: swapper/0 Not tainted 4.6.4-dwrr #11
[    0.167740] Hardware name: Supermicro H8SGL/H8SGL, BIOS 2.0a       11/11/2011
[    0.167741] task: ffff88080d8e8000 ti: ffff88040dd88000 task.ti: ffff88040dd88000
[    0.167743] RIP: 0010:[<ffffffff810b6fda>]  [<ffffffff810b6fda>] task_tick_fair+0xea/0x9e0
[    0.167744] RSP: 0018:ffff88040fc03dc0  EFLAGS: 00010046
[    0.167745] RAX: 00000000005b8d7e RBX: ffff88040fc16c80 RCX: 00000000010e1c7a
[    0.167746] RDX: 0000000000000000 RSI: ffff88040fc16e48 RDI: 00000000005b8d80
[    0.167747] RBP: ffff88040fc03e30 R08: ffff88040fc16d00 R09: 0000000000000001
[    0.167747] R10: 0000000000000000 R11: ffff88040fc16c80 R12: ffff88040fc16d00
[    0.167748] R13: 00000000000003cc R14: ffff88080d8e8080 R15: 00000000051be773
[    0.167750] FS:  0000000000000000(0000) GS:ffff88040fc00000(0000) knlGS:0000000000000000
[    0.167750] CS:  0010 DS: 0000 ES: 0000 CR0: 0000000080050033
[    0.167751] CR2: 0000000000000050 CR3: 0000000001c06000 CR4: 00000000000406f0
[    0.167752] Stack:
[    0.167754]  ffff88080d8e8000 ffff88040fc16c80 ffff88040fc16c80 0000000000000000
[    0.167756]  0000000000000400 0000000000000001 000000000558e4e3 0000000000000000
[    0.167757]  ffffffff810ac372 ffff88040fc16c80 0000000000000000 0000000000016c80
[    0.167757] Call Trace:
[    0.167762]  <IRQ>
[    0.167763]  [<ffffffff810ac372>] ? sched_clock_cpu+0x72/0xa0
[    0.167765]  [<ffffffff810a81dc>] scheduler_tick+0x5c/0xd0
[    0.167767]  [<ffffffff810eab71>] update_process_times+0x51/0x60
[    0.167769]  [<ffffffff810f7c9b>] tick_periodic+0x2b/0x80
[    0.167771]  [<ffffffff810f7d15>] tick_handle_periodic+0x25/0x70
[    0.167774]  [<ffffffff810306f5>] timer_interrupt+0x15/0x20
[    0.167776]  [<ffffffff810d7fc4>] handle_irq_event_percpu+0x44/0x1c0
[    0.167778]  [<ffffffff810d817e>] handle_irq_event+0x3e/0x60
[    0.167779]  [<ffffffff810db4d1>] handle_level_irq+0x91/0x110
[    0.167781]  [<ffffffff8103008d>] handle_irq+0x1d/0x30
[    0.167785]  [<ffffffff817df7fd>] do_IRQ+0x4d/0xd0
[    0.167787]  [<ffffffff817dd902>] common_interrupt+0x82/0x82
[    0.167789]  <EOI>
[    0.167789]  [<ffffffff810d665d>] ? console_unlock+0x4ad/0x550
[    0.167791]  [<ffffffff810d6925>] vprintk_emit+0x225/0x480
[    0.167792]  [<ffffffff810d6cd9>] vprintk_default+0x29/0x40
[    0.167794]  [<ffffffff81184d59>] printk+0x4d/0x4f
[    0.167798]  [<ffffffff81d6ef43>] smp_store_boot_cpu_info+0xf7/0x19e
[    0.167800]  [<ffffffff81d6f049>] native_smp_prepare_cpus+0x5f/0x3d8
[    0.167802]  [<ffffffff81d59204>] kernel_init_freeable+0xb5/0x21b
[    0.167805]  [<ffffffff817d0a5e>] kernel_init+0xe/0x110
[    0.167806]  [<ffffffff817dd1e2>] ret_from_fork+0x22/0x40
[    0.167808]  [<ffffffff817d0a50>] ? rest_init+0x80/0x80
[    0.167824] Code: 38 0f 84 d7 06 00 00 8b 0d 90 5e b9 00 48 39 ca 72 28 49 8b 4c 24 40 48 8d 51 f0 48 85 c9 b9 00 00 00 00 48 0f 44 d1 49 8b 4e 50 <48> 2b 4a 50 78 09 48 39 c8 0f 82 55 06 00 00 4d 8b b6 50 01 00
[    0.167826] RIP  [<ffffffff810b6fda>] task_tick_fair+0xea/0x9e0
[    0.167826]  RSP <ffff88040fc03dc0>
[    0.167827] CR2: 0000000000000050
[    0.167832] ---[ end trace 0cf8749a36857b7f ]---
[    0.167833] Kernel panic - not syncing: Fatal exception in interrupt
[    0.477095] ---[ end Kernel panic - not syncing: Fatal exception in interrupt

```

여기서는 X86 계열의 명령어가 보이므로 IP(Instruction Pointer)에 저장된 주소를 이용해야 한다. `IP`가 나타내고 있는 주소값을 이용하여 아래와 같이 명령어를 이용하면 코드 레벨에서 어느 위치를 실행하고 있었는지를 단번에 알아낼 수 있다.

``` shell
addr2line -e vmlinux ffffffff810b6fda
/home/xpenguin/groupamp/linux-4.6.4/kernel/sched/fair.c:3705
```

그렇다면, vmlinux 파일이 무엇이길래 이러한 디버깅이 가능한 것일까? 여기에 대해 간단하게 명시된 스택오버플로우 페이지가 있었다. 출처로써 명시하기에는 민망하지만, vmlinux 관련 포맷에 대해 간략하게 설명되어 있기에 출처로써 작성하였다.

- vmlinux : Linux kernel in an statically linked executable file format. (raw vmlinux 파일의 경우 디버깅 목적으로 *매우 유용하게* 사용될 수 있음)

- vmlinux.bin: vmlinux의 bootable raw binary 파일 포맷 버전으로, vmlinux 파일을 이용하여 `objcopy -O binary vmlinux vmlinux.bin` 명령어를 통해 생성해낼 수 있다. 이 파일에는 모든 심볼 정보와 재배치 정보가 삭제되어 있다.

- vmlinuz: vmlinux의 `zlib`을 이용해 압축된 형태
- zImage: small kernel(compressed, below 512KB)의 오래된 버전
- bzImage: 'big zImage' 의미로서 `bzip2`와는 무관하며, (compressed, over 512KB) zImage에 비해 용량이 큰 버전이다.

## 출처

- <https://unix.stackexchange.com/questions/5518/what-is-the-difference-between-the-following-kernel-makefile-terms-vmlinux-vml>

- <http://egloos.zum.com/holypsycho/v/3548805>
