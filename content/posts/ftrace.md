---
title: "ftrace 이용한 커널 디버깅"
date: 2020-02-06T23:43:34+09:00
categories:
- Kernel
tags:
- debug
- ftrace
---

# 개요
커널 디버깅을 위해 procfs, sysfs, 레지스터 덤프 등의 단순 정보를
제외한 다른 방법은 없을까? 업무에서 문제 원인 파악을 위해서는 디버깅이
중요한데 커널에서는 사용할 수 있는 디버깅 툴이 제한적이다. 또한, 팀
내에서도 로그나 레지스터 외에 별다른 디버깅 도구를 사용하는 것 같지
않아, 다른 방법이 있는지 찾아보던 중 익숙한 이름의 `ftrace`가 있다는
것을 알게 됐다.

예전에 젠투 리눅스를 사용할 무렵, `menuconfig`에서 커널 해킹이라는
흥미로운 메뉴에서 알 수 없는 `tracer`라는 메뉴로만 본 것으로 이해하지
직접적으로 사용한 적은 없었는데, 실제 사용해보니 생각보다 많은 옵션,
정보들을 보여주었다.

# ftrace란?
`ftrace`는 리눅스 커널에서 제공하는 트레이서로, 커널의 세부 동작을
알기 쉽게(?) 출력해주는 도구이다. 특징은 아래와 같다.

1. 인터럽트, 스케쥴링, 커널 타이머 동작을 상세하게 추적해준다.
2. 함수 필터를 지정하면 자신을 호출한 함수와 전체 콜 스택까지
   출력해준다. 이 때, 코드를 수정할 필요가 없다.
3. 함수를 어느 프로세스가 실행하는지 알 수 있다.
4. 함수 실행 시각을 알 수 있다.
5. ftrace 로그를 키면 시스템 동작에 부하를 주지 않는다.

# 커널에서 ftrace 활성화하기
`ftrace`를 사용하기 위해서는 관련된 설정 플래그를 활성화해줘야 한다.

```
CONFIG_FTRACE=y
CONFIG_DYNAMIC_FTRACE=y
CONFIG_FUNCTION_TRACER=y
CONFIG_FUNCTION_GRAPH_TRACER=y
CONFIG_IRQSOFF_TRACER=y
CONFIG_SCHED_TRACER=y
CONFIG_FUNCTION_PROFILER=y
CONFIG_STACK_TRACER=y
CONFIG_TRACER_SNAPSHOT=y
```

라즈베리파이에서는 기본으로 `ftrace`에 필요한 세부 설정 플래그가 모두
켜져 있다. 또한 `ftrace`는 리눅스 커널 공통 기능이므로 다른
시스템에서도 사용 가능하다.

커널 2.6.28 버전부터 포함된 기본 기능으로서 아래와 같이 `debugfs`를
마운트 시켜서 사용할 수 있다.

```
mount -t debugfs nodev /sys/kernel/debug
```

# `ftracer` 설정 방법
아래와 같이 셸 스크립트를 이용하여 설정도 가능하지만 기본적으로는
`sysfs`를 이용하여 설정을 한다. 설정 시나리오는 tracer를 OFF 한 뒤에
옵션들을 설정해주고 다시 ON하는 방식으로 설정한다.

``` shell
#!/bin/sh

echo 0 > /sys/kernel/debug/tracing/tracing_on
sleep 1
echo "tracing_off"
7 echo 0 > /sys/kernel/debug/tracing/events/enable
sleep 1
echo "events disabled"

 echo  secondary_start_kernel  > /sys/kernel/debug/tracing/set_ftrace_filter
 sleep 1
 echo "set_ftrace_filter init"

 echo function > /sys/kernel/debug/tracing/current_tracer
 sleep 1
 echo "function tracer enabled"

 echo 1 > /sys/kernel/debug/tracing/events/sched/sched_wakeup/enable
 echo 1 > /sys/kernel/debug/tracing/events/sched/sched_switch/enable

 echo 1 > /sys/kernel/debug/tracing/events/irq/irq_handler_entry/enable
 echo 1 > /sys/kernel/debug/tracing/events/irq/irq_handler_exit/enable

 echo 1 > /sys/kernel/debug/tracing/events/raw_syscalls/enable
 sleep 1
 echo "event enabled"

 echo  schedule ttwu_do_wakeup > /sys/kernel/debug/tracing/set_ftrace_filter

 sleep 1
 echo "set_ftrace_filter enabled"

 echo 1 > /sys/kernel/debug/tracing/options/func_stack_trace
 echo 1 > /sys/kernel/debug/tracing/options/sym-offset
 echo "function stack trace enabled"

 echo 1 > /sys/kernel/debug/tracing/tracing_on
 echo "tracing_on"
```

리눅스에서는 nop, function, function_graph를 포함한 여러가지
트레이서를 제공한다.

- nop: 기본 트레이서로 ftrace 이벤트만 출력
- function: `set_ftrace_filter`로 지정한 함수를 누가 호출하는지
  출력한다.
- function_graph: 함수 실행 시간과 세부 호출 정보를 그래픽 정보를
  추가(?)해 출력한다.

# ftracer 사용 예
아래는 출처에서 기술되어 있는 예시들을 한 데 정리한 것이다. 이 후,
업무에서 사용한 이력이나 팁이 있는 경우에 이 곳에 관련 내용을
추가하도록 한다.

## 커널 함수 추적하기
커널 함수들이 호출되는 과정을 살펴본다. 우선 tracing 디렉토리로
이동해서 추적할 수 있는 항목들을 알아보자.

``` shell
tracing $ cat available_tracers
blk kmemtrace function_graph wakeup_rt wakeup function sysprof sched_switch initcall nop

tracing $ echo function > ./current_tracer
```

위에서처럼 tracer의 모드를 설정한 후 `vi`로 trace 파일을 열어보면
아래와 같은 내용을 볼 수 있다.

```
# tracer: function
#
#           TASK-PID    CPU#    TIMESTAMP  FUNCTION
#              | |       |          |         |
            sshd-15219 [000] 159421.106063: __math_state_restore <-__switch_to
            sshd-15219 [000] 159421.106064: finish_task_switch <-thread_return
            sshd-15219 [000] 159421.106065: fget_light <-do_select
            sshd-15219 [000] 159421.106065: sock_poll <-do_select
            sshd-15219 [000] 159421.106066: tcp_poll <-sock_poll
            sshd-15219 [000] 159421.106066: fget_light <-do_select
            sshd-15219 [000] 159421.106066: pipe_poll <-do_select
```

또한, 프로세스 별로 호출하고 있는 커널 함수를 직접 살펴볼 수도 있다.

```
[root@server tracing]# echo function_graph > ./current_tracer

 0)               |    do_vfs_ioctl() {
 0)               |      vfs_ioctl() {
 0)               |        tty_ioctl() {
 0)   0.349 us    |          tty_paranoia_check();
 0)   0.301 us    |          pty_unix98_ioctl();
 0)               |          tty_ldisc_ref_wait() {
 0)               |            tty_ldisc_try() {
 0)   0.301 us    |              _spin_lock_irqsave();
```

## 스케쥴링 과정 보기


# 출처
- https://kldp.org/node/161282
- https://brunch.co.kr/@alden/24
