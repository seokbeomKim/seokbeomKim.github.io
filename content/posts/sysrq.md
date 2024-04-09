---
draft: true
title: "sysrq 이용한 커널 패닉 발생시키기"
date: 2020-12-17T01:38:06+09:00
categories:
- Kernel
tags:
- sysrq
---

# 개요

현업에서 커널 패닉을 고의로 생성하기 위해서 찾아보던 중 *sysrq* 를
이용하는 방법이 있다는 것을 알게 되었다. 본 페이지에서는 sysrq에 대한
개념과 사용 방법 등에 대해서 정리하도록 한다.

## 기능 활성화

*SysRq* 이 컴파일된 커널을 실행하면 */proc/sys/kernel/sysrq* 를 통해서
원하는 기능을 활성화/비활성화 할 수 있다. 사용 가능한 sysrq 값들은
*/proc/sys/kernel/sysrq* 내에 정의되어 있으며 기본값들은
*CONFIG_MAGIC_SYSRQ_DEFAULT_ENABLE* 값으로 설정한다.

- 0 - disable sysrq completely
- 1 - enable all functions of sysrq
- \>1 - bitmask of allowed sysrq functions (see below for detailed
function description):

    ```

      2 =   0x2 - enable control of console logging level
      4 =   0x4 - enable control of keyboard (SAK, unraw)
      8 =   0x8 - enable debugging dumps of processes etc.
     16 =  0x10 - enable sync command
     32 =  0x20 - enable remount read-only
     64 =  0x40 - enable signalling of processes (term, kill, oom-kill)
    128 =  0x80 - allow reboot/poweroff
    256 = 0x100 - allow nicing of all RT tasks
    ```

## 사용법

[https://www.kernel.org/doc/html/v4.11/admin-guide/sysrq.html](https://www.kernel.org/doc/html/v4.11/admin-guide/sysrq.html)
페이지에 따르면 */proc/sysrq-trigger* 에 아래와 같이 특정 캐릭터를
사용하여 커맨드 키를 호출할 수 있다.

```
echo t > /proc/sysrq-trigger
```

통상 커널 디버깅을 위해 사용한다고 생각하며, 다양한 디버깅 상황을
발생시키기 위해 유용하게 사용할 수 있다.

# 출처

- [https://www.kernel.org/doc/html/v4.11/admin-guide/sysrq.html](https://www.kernel.org/doc/html/v4.11/admin-guide/sysrq.html)
- [https://unix.stackexchange.com/questions/66197/how-to-cause-kernel-panic-with-a-single-command](https://unix.stackexchange.com/questions/66197/how-to-cause-kernel-panic-with-a-single-command)
