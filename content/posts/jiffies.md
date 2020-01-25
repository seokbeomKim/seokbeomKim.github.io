---
title: "지피(Jiffies)"
date: 2019-05-26T10:38:40+09:00
categories:
- O/S
- Linux
- Kernel
tags:
- jiffies
keywords:
- tech
---

<!-- toc -->

오랜만에 지피에 대한 포스팅을 다시 작성한다(대학생 때 커널 공부를 한
뒤로 이렇게 별도로 문서를 작성하는 것은 처음인 것 같다). 전역 변수인
`jiffies`에는 시스템 시작 이후 발생한 진동 횟수(tick)이
저장된다. 시스템 시작 시 커널은 이 값을 0으로 설정하고 타이머
인터럽트가 발생할 때마다 1씩 증가시킨다. 타이머 인터럽트는 초당 HZ회
발생하므로, 초당 지피 수는 HZ가 되며, 이에 따라 시스템 가동 시간은
`jiffies / HZ`(초)가 된다.

커널은 버그 식별을 위해 jiffies 변수의 오버플로우 현상이 자주 일어나기
위해 jiffies 변수를 0이 아닌 특별한 값으로 초기화하며 실제 jiffies값이
필요한 경우에는 이 차이(offset)값을 빼야 한다.

# 지피 비교를 위한 매크로
`jiffies`는 `unsigned long` 타입으로 언젠가는 오버플로우가 발생하게
된다. 오버플로우에 대한 내용을 찾던 중 재미있는 함수를 발견했는데 이와
관련해 잠깐 설명하고자 한다.

#define time_after(a,b)		\
	(typecheck(unsigned long, a) && \
	 typecheck(unsigned long, b) && \
	 ((long)((b) - (a)) < 0))
#define time_before(a,b)	time_after(b,a)

#define time_after_eq(a,b)	\
	(typecheck(unsigned long, a) && \
	 typecheck(unsigned long, b) && \
	 ((long)((a) - (b)) >= 0))
#define time_before_eq(a,b)	time_after_eq(b,a)

예전에 지피(jiffies) 비교 매크로를 보면서 이게 어떻게 작동할 수 있는지
확실하게 이해하지 못했었는데 이는 `signed, unsigned와 실제 바이트와의
관계`를 내가 정확하게 이해하지 못하고 있었기 때문이었다.

맘에 들지는 않지만, 스택 오버플로우에 매우 친절하게 설명되어 있는
답변이 있었다. unsigned와 signed의 관계를 자세하게 나타냈는데 아래와
같이 표현해주었다. 아래 그림(?)은 편의상 `unsigned long` 대신
`unsigned int`와 `signed int`의 관계를 나타낸 그림이다.

``` text
[0x0      -              -                  -               0xFFFF]
[0x0                       0x7FFF][0x8000                   0xFFFF]
[0                         32,767][-32,768                      -1]
```

integer unsigned 형태는 0x0부터 0xFFFF(4bytes, 2^32)까지의 값 범위를
가지고 있고 signed는 그 절반을 갖고 있다. 이 때 중요한 점은 signed의
양수 범위를 초과하는 순간 -1로 되는 것이 아니라 음수 최소값으로
돌아간다는 점이다. 그러므로 0xFFFF는 -1이 된다.

지피를 비교하는 경우로 다시 돌아가보자. 비교할 지피 `t1, t2`에 대해 1)
모두 양수인 경우, 2) 모두 음수인 경우, 3) 한쪽은 양수, 한쪽은 음수인
경우를 생각해 볼 수 있다.

이를 비교하기 위해 아래와 같이 간단하게 코드를 짜본뒤 확인해보자.

/* unsigned long 오버플로우 검사 */
unsigned long t1 = 0; // 0x0
unsigned long t2 = 1;
unsigned long t3 = (t1 - 1); // 0xffffffff
unsigned long t4 = (t1 - 1) / 2; // 중간 값(signed 최대)

printf("(unsigned)t1 = %lu, t2 = %lu, t3 = %lu, t4 = %lu\n", t1, t2, t3, t4);
printf("(signed)t1 = %ld, t2 = %ld, t3 = %ld, t4 = %ld, t4+1 = %ld\n", t1, t2, t3, t4, t4+1);

/* case 1. 비교 대상이 모두 양수일 때  */
printf("case 1: t1 - t2 as long: %ld\n", (long)t1 - (long)t2);

/* case 2. 비교 대상이 모두 음수일 때 */
printf("case 2: (t4 + 1) - (t4 + 2): %ld\n", (t4+1) - (t4+2));

/* case 3-1. 비교 대상이 서로 다른 부호일 때 */
printf("case 3-1: t3 - t1 as long: %ld\n", (long)((t3) - (t1)));

/* case 3-2. 비교 대상이 서로 다른 부호일 때 */
printf("case 3-2: t4 - (t4 + 1): %ld\n", (long)t4 - (long)(t4 + 1));

이에 대한 출력 결과는 다음과 같다.

```
(unsigned)t1 = 0, t2 = 1, t3 = 18446744073709551615, t4 = 9223372036854775807
(signed)t1 = 0, t2 = 1, t3 = -1, t4 = 9223372036854775807, t4+1 = -9223372036854775808
case 1: t1 - t2 as long: -1
case 2: (t4 + 1) - (t4 + 2): -1
case 3-1: t3 - t1 as long: -1
case 3-2: t4 - (t4 + 1): -1
```

즉, 앞서가는 unsigned, signed의 특성 상 앞서가는 포인트에 대해 signed
범위 안에서 값을 비교하면 그 결과 범위가 양수 또는 음수로 나오게 된다.


# 매크로 속 typecheck
여기서 사용된 `typecheck` 함수를 잠깐 살펴보자. typecheck는 무조건
참(1) 값을 반환하는 매크로 함수이다. 그럼에도 사용하는 이유는 컴파일
타임에서 인자로 전달한 타입과 변수의 타입을 서로 비교하여 같은지
여부를 나타낼 수 있는 일종의 트릭을 사용하고 있기 때문이다. (커널
해킹을 시작한지 얼마되지 않은 시점에서 오랜만에 느껴보는 즐거움이다.)
아래는 typecheck를 구현한 코드이다.

#define typecheck(type,x) \
({ type __dummy; \
typeof(x) __dummy2; \
(void)(&__dummy == &__dummy2); \
1; \
})

재미있는 것은 반환값은 항상 1이지만 반환 전에 `(void)(&__dummy ==
&__dummy2);` 부분을 통해 각 변수의 타입으로 만든 포인터가 일치하는지를
경고 또는 에러 메세지로 출력한다. 런타임 시의 결과를 기대하는 코드가
아니라, 컴파일 시의 결과를 기대하며 짠 코드인만큼 컨셉 자체가 정말
신선하게 다가왔다.

이러한 코드는 아래와 같이 컴파일을 통해 출력 값을 기대할 수
있다. `unsigned long` 타입은 `j1`의 변수를 `int`과 비교하는
경우이다. 이러한 예제를 아래 스크린샷처럼 `-Werror` 옵션과 함께
컴파일하게 되면 타입 에러를 사전에 감지해낼 수 있다.

int a = 1;
unsigned long j1 = 12345678;
unsigned long j2 = 23456789;
if (typecheck(int,a) && typecheck(int, j1) && typecheck(unsigned long, j2)) {
    printf("a value is int and (j1, j2) is unsigned long\n");
} else {
    printf("a value is not int\n");
}


![컴파일 타임 에러](/img/gcc_werror.png)

# 지피(jiffies)는 누가 증가시키는가?
앞서, `"지피(jiffies)에는 시스템 시작 이후 발생한 진동 횟수(tick)가
저장된다."`라고 말했다. 그렇다면 그러한 tick은 누가 발생시킬까? 이를
위한 것이 바로 시스템 타이머이다.

시간 기록을 위해서 리눅스에서는 RTC(Real Time Clock), 시스템 타이머를
이용한다.

## '시간'에 관련된 하드웨어
RTC는 보통 시스템 기판에 붙어 있는 원형 배터리를 통해 시스템이 꺼져
있는 동안에도 시간을 기록하며 일반적인 PC 아키텍처인 경우 RTC와 CMOS가
통합되어 있는 것을 확인할 수 있다.<br>커널은 시스템 시작 시 RTC를 읽고
`xtime`변수에 저장되는 현재 시간을 초기화한다. 보통 커널은 최초
init에만 RTC를 읽으며 x86 시스템을 제외하고는 RTC를 다시 읽지 않는다.

시스템 타이머는 커널의 시간 기록에 있어 매우 중요한 역할을 한다. 현재
시간을 초기화할 때 사용되는 RTC와는 달리 시스템 타이머는 주기적으로
인터럽트를 발생시킨다. 그리고 커널은 이러한 타이머 인터럽트에 대한
인터럽트 핸들러를 내부에 가지고 있어 아래와 같은 작업들을 처리한다.<br><br>

1. jiffies_64 및 현재 시간을 저장하는 xtime 변수에 안전하게 접근하기
   위해 xtime_lock을 얻는다.
2. 필요에 따라 시스템 타이머를 확인하고 재설정한다.
3. 갱신된 현재 시간을 주기적으로 실시간 시계에 반영한다.
4. **아키텍처 종속적** 타이머 함수인 `tick_periodic()` 함수를 호출한다.

## 커널 코드 속 시스템 타이머 인터럽트 핸들러

그렇다면, 직접 타이머 인터럽트 핸들러를 따라가보자. 커널 분석 책에는
아키텍처 종속적인 부분은 시스템 타이머의 인터럽트 핸들러 형태로 되어
있으며 타이머 인터럽트가 발생했을 때 실행된다고 되어 있다. 하지만 실제
커널(v4.20.x)에는 `tick-common.h` 안에 하나로 통합되어
있었다. `tick-internal.h` 헤더파일에는 `tick_set_periodic_handler`라는
함수가 정의되어 있다. 타이머 인터럽트에 대한 핸들러를 등록하는
함수로서 `clock_event_device`(시스템 타이머 장치) 디바이스의 이벤트
핸들러로 등록하는 부분이다.

/* Set the periodic handler in non broadcast mode */
static inline void tick_set_periodic_handler(struct clock_event_device *dev, int broadcast)
{
	dev->event_handler = tick_handle_periodic;
}

이제, `tick_handle_periodic()` 인터럽트 핸들러를 살펴보자.

/*
 * Event handler for periodic ticks
 */
void tick_handle_periodic(struct clock_event_device *dev)
{
	int cpu = smp_processor_id();
	ktime_t next = dev->next_event;

	tick_periodic(cpu);

#if defined(CONFIG_HIGH_RES_TIMERS) || defined(CONFIG_NO_HZ_COMMON)
	/*
	 * The cpu might have transitioned to HIGHRES or NOHZ mode via
	 * update_process_times() -> run_local_timers() ->
	 * hrtimer_run_queues().
	 */
	if (dev->event_handler != tick_handle_periodic)
		return;
#endif

	if (!clockevent_state_oneshot(dev))
		return;
	for (;;) {
		/*
		 * Setup the next period for devices, which do not have
		 * periodic mode:
		 */
		next = ktime_add(next, tick_period);

		if (!clockevents_program_event(dev, next, false))
			return;
		/*
		 * Have to be careful here. If we're in oneshot mode,
		 * before we call tick_periodic() in a loop, we need
		 * to be sure we're using a real hardware clocksource.
		 * Otherwise we could get trapped in an infinite
		 * loop, as the tick_periodic() increments jiffies,
		 * which then will increment time, possibly causing
		 * the loop to trigger again and again.
		 */
		if (timekeeping_valid_for_hres())
			tick_periodic(cpu);
	}
}


책에서는 *"아키텍처 종속적인 부분은 시스템 타이머의 인터럽트 핸들러
형태로 되어 있으며, 타이머 인터럽트가 발생했을 때 실행된다."* 라고
되어 있으나, 실제 `tick_periodic` 자체는 아키텍처 종속 코드가 발견되지
않았다. 대신 cpu 아이디를 얻어오는 부분에 대해 아래와 같은 코드를
발견할 수 있었다.

#ifdef CONFIG_DEBUG_PREEMPT
  extern unsigned int debug_smp_processor_id(void);
# define smp_processor_id() debug_smp_processor_id()
#else
# define smp_processor_id() raw_smp_processor_id()
#endif

그리고 `raw_smp_processor_id()`에 대해서는 아키텍처 별로 종속적인
코드가 들어가 있는 것을 확인할 수 있다. 한 예로, x86 코드를 살펴보면
아래와 같이 정의된다.

#define raw_smp_processor_id() (this_cpu_read(cpu_number))

여기서 더 깊게 들어가는 것은 그만두고 다시 원점으로 돌아가, 시스템
타이머 인터럽트 핸들러에서 SMP(Symmetric Multiprocessing)에 관련,
아키텍처에 종속된 코드가 실행된다는 것을 파악하였다. 이제
`tick_periodic()`을 살펴보자.

static void tick_periodic(int cpu)
{
	if (tick_do_timer_cpu == cpu) {
		write_seqlock(&jiffies_lock);

		/* Keep track of the next tick event */
		tick_next_period = ktime_add(tick_next_period, tick_period);

		do_timer(1);
		write_sequnlock(&jiffies_lock);
		update_wall_time(); // 진동수 경과에 맞춰 현재 시간을 갱신한다.
	}

	update_process_times(user_mode(get_irq_regs()));
	profile_tick(CPU_PROFILING);
}

이 함수에서 눈여겨볼 부분은 `do_timer()`와 `update_process_times()`
부분이다. `do_timer()` 함수는 실제 지피값을 증가시키는 작업을 담당하며
해당 코드는 아래와 같다. 커널은 전자 함수를 통해 지비를 발생한 틱만큼
증가시키고 후자를 통해 시스템의 평균 로드 통계를 갱신한다.

void do_timer(unsigned long ticks)
{
	jiffies_64 += ticks;
	calc_global_load(ticks);
}

void update_process_times(int user_tick)
{
	struct task_struct *p = current;

	/* Note: this timer irq context must be accounted for as well. */
	account_process_tick(p, user_tick);
	run_local_timers();
	rcu_check_callbacks(user_tick);
#ifdef CONFIG_IRQ_WORK
	if (in_irq())
		irq_work_tick();
#endif
	scheduler_tick();
	if (IS_ENABLED(CONFIG_POSIX_TIMERS))
		run_posix_cpu_timers(p);
}


`update_process_times`는 `run_local_timers()`를 통해 로컬 타이머, 즉
softirq를 발생시켜 시간이 만료된 타이머를 실행한다.

# 출처
* [how does linux handle overflow in
  jiffies](https://stackoverflow.com/questions/8206762/how-does-linux-handle-overflow-in-jiffies)
