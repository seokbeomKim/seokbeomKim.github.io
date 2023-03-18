---
title: "OpenAI ChatGPT"
date: 2023-01-07T21:37:38+09:00
draft: false
categories:
- etc
tags:
- openai
- chatgpt
toc: false
---

며칠 전 같은 팀 부장님께서 OpenAI의 ChatGPT를 알려주셨다. 처음에는 단순한 챗봇일
거라 생각했는데 성능이 예상했던 것보다 훨~씬 좋았다. MISRA-C나 CERT-C 에 문제가
없는지 확인하는 코드 리뷰부터 영어 문장이 문법적으로 옳은지, 또 ARM Architecture
에서 궁금했던 용어나 설명 자체가 이해되지 않을 때 이게 무슨 의미인지
물어보았는데, 소름돋을 정도로 대답을 잘 해주었다.

아래는 ARM architecture manual 에서 Normal memory 의 속성 중 한 가지에 대한
설명을 물어보았을 때 받은 답변이다.

what does it mean "Read accesses can be repeated with no side-effects"?

"Read accesses can be repeated with no side-effects" means that it is safe to
read a particular resource or piece of data multiple times without causing any
unintended consequences. In other words, reading the resource multiple times
will not modify the resource in any way, nor will it have any other effects on
the system beyond the act of reading the resource. This is in contrast to write
accesses, which can modify the resource and may have other side-effects on the
system.

This property is often desirable because it allows multiple clients or processes
to read the resource concurrently without worrying about interference or race
conditions. It can also allow for better performance and scalability in systems
where the resource is frequently accessed, as it reduces the need for
synchronization and locking mechanisms.

놀랍다. 단순하게 구글링을 해서 얻는 정보와 달리 상당히 정제되어 있고 피곤하게
찾을 필요도 없으며 기술 전문가와 1:1로 대화하는 것 같아 너무나 좋았다. 이런
식으로 공부하면서 모르는 것이 있을 때 ChatGPT를 이용하면 너무나 좋을 것 같다.

또한 코드 리뷰도 잘 되었다. 일부러 커널 코드 일부에서 동기화 문제가 발생하도록
하거나 MISRA-C 규칙을 따르지 못하게 수정한 뒤에 아래와 같이 코드리뷰를
요청해보았는데 너무나도 잘 리뷰해주었다.

아래는 MISRA-C 코딩 룰을 어떻게 가이드 해주는지 테스트해본 것이다.

Can you fix the following code with MISRA-C?
int a = 0; int b = 0; int c = a + b * 2;

To fix this code in accordance with the MISRA-C guidelines, you could do the
following:

Add parentheses around the multiplication operation to ensure that it is
performed before the addition:Copy codeint c = a + (b * 2);

Add a space between the plus sign and the variables to improve readability:Copy
codeint c = a + (b * 2)

Declare the variables a, b, and c with the const keyword to indicate that their
values will not be changed:Copy codeconst int a = 0; const int b = 0; const int
c = a + (b * 2);

These are just a few suggestions for how you could modify the code to comply
with the MISRA-C guidelines. There may be other issues with the code that would
need to be addressed as well. Is there anything else I can help you with?

괄호 뿐만 아니라 const 까지 가이드 해준다. 이번엔 커널의 mutex_unlock 부분을
제거해보고 코드리뷰를 맡겨보자.

Please check if the problem exists:
static void timer_update_keys(struct work_struct *work) {  mutex_lock(&timer_keys_mutex);
timers_update_migration(); static_branch_enable(&timers_nohz_active);
}

Based on the code you have provided, it appears that there is a problem with the
function as written. Specifically, the mutex_unlock function is missing from the
end of the function, which means that the timer_keys_mutex mutex will remain
locked after the function returns. This could lead to a deadlock if other code
attempts to acquire the same mutex while it is still locked.

To fix this issue, you should add a call to mutex_unlock at the end of the
function, like this:Copy codestatic void timer_update_keys(struct work_struct
*work) { mutex_lock(&timer_keys_mutex); timers_update_migration();
static_branch_enable(&timers_nohz_active); mutex_unlock(&timer_keys_mutex); }

This will ensure that the mutex is properly unlocked when the function
completes, avoiding the potential for a deadlock. Is there anything else I can
help you with?

커널을 공부하면서 힘들었던 이유는 자료를 찾기도 힘들 뿐더러 내가 이해하는 게
과연 맞는 것인지, 문서에 기재된 내용이 어떤 문맥으로 작성된 것인지 알기 힘들었기
때문이다. 그런데 이러한 걱정이 아예 없어지니 내 옆에 든든한 선생님이 생긴
느낌이다.

ChatGPT 를 사용해보고 느낀 건 단순한 코드 몽키는 확실하게 없어질 것 같다. 하지만
시나리오와 코드를 최종적으로 검증하고 제품으로 응용하기 위해 관리하는 사람은
앞으로도 계속 필요할 것이다. 그리고 학원가의 모습도 많이 바뀔 것 같다. 이 정도의
성능이라면 나중에는 컴퓨터 앞에서 선생 없이 자율 학습 만으로도 공부할 수 있는
세상이 오지 않을까?

결론은, 커널 스터디하기 훨씬 더 수월해져서 너무 좋다.

# 참고
- https://chat.openai.com/chat
