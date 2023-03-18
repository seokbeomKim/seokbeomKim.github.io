---
title: "커널의 KASAN 코드가 삽입되는 방법"
date: 2021-09-24T01:13:41+09:00
draft: false
categories:
- Kernel
tags:
- kasan
- gcc
---

# 커널의 KASAN 코드가 삽입되는 방법
Generic KASAN 의 경우, 위와 같이 `__asan_load`와 `__asan_store` 함수가 정의되어
있다. 단순하게 KASAN의 사용법만 보았을 때, 과연 커널에서 어떻게 모든 메모리에
접근할 때마다 특정 함수의 내용을 실행할까 라는 궁금증이 생겼다. 커널 문서에
따르면, 컴파일러에 의해 위 함수들이 인라인 형태로 모든 메모리 접근 전에 삽입되어
해당 메모리가 안전한지 확인한다고 기술하고 있다. 이에 처음에는 `static inline`
형태로 정의된 함수가 컴파일러에 의해 처리되는 것인가? 라고 생각했다. 하지만,
실제 코드를 보았을 때 함수와 `EXPORT_SYMBOL` 이 사용된 것 외에는 그 어디에도
inline 키워드는 사용도지 않았다. 컴파일러가 해당 코드를 삽입한다고 하는데
정확하게 어떻게 삽입하는지, 해당 함수들의 이름이 바뀌면 어떤 결과가 나올지
궁금했다. 또한 커널 소스를 다 뒤져봐도 ASAN에 관련된 호출 부분을 아무리 찾아도
어떤 방식으로 `__asan_loadN`, `__asan_storeN` 이 메모리 접근 전에 삽입되는지
찾을 수 없었다.

KASAN 지원 여부가 컴파일러 버전에 따라 달라지는 것을 확인하고, 이에 컴파일러가
관련된 코드를 삽입하는 것을 직접 확인하기 위해 GCC 코드를 살펴보았다.

# GCC 코드

GCC 코드(`$gcc_root/gcc/sanitizer.def`)에는 커널에서 __asan_* 형태로 정의해놓은
심볼에 대해 `DEF_SANITIZER_BUILTIN` 이라는 매크로와 함께 아래와 같이
정의해놓았다.

```c
DEF_SANITIZER_BUILTIN(BUILT_IN_ASAN_LOAD1, "__asan_load1",
		      BT_FN_VOID_PTR, ATTR_TMPURE_NOTHROW_LEAF_LIST)
DEF_SANITIZER_BUILTIN(BUILT_IN_ASAN_LOAD2, "__asan_load2",
		      BT_FN_VOID_PTR, ATTR_TMPURE_NOTHROW_LEAF_LIST)
DEF_SANITIZER_BUILTIN(BUILT_IN_ASAN_LOAD4, "__asan_load4",
		      BT_FN_VOID_PTR, ATTR_TMPURE_NOTHROW_LEAF_LIST)
DEF_SANITIZER_BUILTIN(BUILT_IN_ASAN_LOAD8, "__asan_load8",
		      BT_FN_VOID_PTR, ATTR_TMPURE_NOTHROW_LEAF_LIST)
DEF_SANITIZER_BUILTIN(BUILT_IN_ASAN_LOAD16, "__asan_load16",
		      BT_FN_VOID_PTR, ATTR_TMPURE_NOTHROW_LEAF_LIST)
DEF_SANITIZER_BUILTIN(BUILT_IN_ASAN_LOADN, "__asan_loadN",
		      BT_FN_VOID_PTR_PTRMODE, ATTR_TMPURE_NOTHROW_LEAF_LIST)
DEF_SANITIZER_BUILTIN(BUILT_IN_ASAN_STORE1, "__asan_store1",
		      BT_FN_VOID_PTR, ATTR_TMPURE_NOTHROW_LEAF_LIST)
DEF_SANITIZER_BUILTIN(BUILT_IN_ASAN_STORE2, "__asan_store2",
		      BT_FN_VOID_PTR, ATTR_TMPURE_NOTHROW_LEAF_LIST)
DEF_SANITIZER_BUILTIN(BUILT_IN_ASAN_STORE4, "__asan_store4",
		      BT_FN_VOID_PTR, ATTR_TMPURE_NOTHROW_LEAF_LIST)
DEF_SANITIZER_BUILTIN(BUILT_IN_ASAN_STORE8, "__asan_store8",
		      BT_FN_VOID_PTR, ATTR_TMPURE_NOTHROW_LEAF_LIST)
DEF_SANITIZER_BUILTIN(BUILT_IN_ASAN_STORE16, "__asan_store16",
		      BT_FN_VOID_PTR, ATTR_TMPURE_NOTHROW_LEAF_LIST)
DEF_SANITIZER_BUILTIN(BUILT_IN_ASAN_STOREN, "__asan_storeN",
```

정의된 SANITIZER 중에서 BUILT_IN_ASAN_LOAD1 을 따라가보면,
`gcc_root/gcc/sanopt.c` 경로에 `pass_sanopt::execute` 메서드로 아래와 같이 enum
형태로 정의되어 있다. 호출 스택은 `pass_sanopt::execute` →
`asan_expand_check_ifn` → `check_func` 으로 구성된다.

```c
static tree
check_func (bool is_store, bool recover_p, HOST_WIDE_INT size_in_bytes,
	    int *nargs)
{
  static enum built_in_function check[2][2][6]
    = { { { BUILT_IN_ASAN_LOAD1, BUILT_IN_ASAN_LOAD2,
	    BUILT_IN_ASAN_LOAD4, BUILT_IN_ASAN_LOAD8,
	    BUILT_IN_ASAN_LOAD16, BUILT_IN_ASAN_LOADN },
	  { BUILT_IN_ASAN_STORE1, BUILT_IN_ASAN_STORE2,
	    BUILT_IN_ASAN_STORE4, BUILT_IN_ASAN_STORE8,
	    BUILT_IN_ASAN_STORE16, BUILT_IN_ASAN_STOREN } },
	{ { BUILT_IN_ASAN_LOAD1_NOABORT,
	    BUILT_IN_ASAN_LOAD2_NOABORT,
	    BUILT_IN_ASAN_LOAD4_NOABORT,
	    BUILT_IN_ASAN_LOAD8_NOABORT,
	    BUILT_IN_ASAN_LOAD16_NOABORT,
	    BUILT_IN_ASAN_LOADN_NOABORT },
	  { BUILT_IN_ASAN_STORE1_NOABORT,
	    BUILT_IN_ASAN_STORE2_NOABORT,
	    BUILT_IN_ASAN_STORE4_NOABORT,
	    BUILT_IN_ASAN_STORE8_NOABORT,
	    BUILT_IN_ASAN_STORE16_NOABORT,
	    BUILT_IN_ASAN_STOREN_NOABORT } } };
  if (size_in_bytes == -1)
    {
      *nargs = 2;
      return builtin_decl_implicit (check[recover_p][is_store][5]);
    }
  *nargs = 1;
  int size_log2 = exact_log2 (size_in_bytes);
  return builtin_decl_implicit (check[recover_p][is_store][size_log2]);
}
```

GCC 코드에서 Optimize and expand sanitizer functions 라고 기술되어 있는 위의
`$gcc_root/gcc/sanopt.c` 파일를 살펴보고 난 뒤, 커널 코드 내에서 별도의 호출
없이 어떻게 "모든" 메모리 접근에 대해 유효성 확인을 하는 코드를 삽입할 수
있는지, Generic KASAN에 관련된 함수들이 실제로 메모리 접근 전 어떻게 inline
형태로 추가되는지 대략적으로 이해할 수 있었다.

결론은 Memory Sanitizer 연관 함수들은 커널에서 정의하였지만 해당 함수들이 실제로
메모리 접근 전에 인라인 또는 아웃라인으로 삽입/호출되는 부분은 컴파일러가 그
역할을 담당한다.
