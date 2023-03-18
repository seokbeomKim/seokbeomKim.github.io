---
title: "리눅스 커널 빌드 시 맥 O/S uuid_t 호환성"
date: 2020-12-24T00:56:38+09:00
categories:
- mac
tags:
- uuid
- kernel
- file2alias
- mac_os
---

## 개요

BSD 기반의 맥에서 리눅스 커널 빌드가 안될리 없다고 생각하고 나서
어떻게든 맥에서 리눅스 커널을 빌드하기 위해 이런저런 삽질을
했다. 회사에서의 BSP 업무는 모두 리눅스 환경 아래에서 작업하기 때문에
사실상 큰 의미는 없겠으나, 빌드만을 위해서 맥에서 도커까지 사용해야
하는 솔루션을 납득할 수 없었다.

이에, [지난
포스팅](https://seokbeomkim.github.io/posts/kernel-compilation-on-mac-os/)에서
열심히 정리해놓은 가이드를 따라 크로스 컴파일러 준비 후, 커널 빌드를
시도하였으나 어찌된 영문인지 file2alias.c 파일에서 계속해서 빌드
에러가 났다. commit 로그를 뒤져보았는데 uuid_t 관련해서 크게 달라진
점은 없었다. 어째서 라즈베리파이 bsp에서는 정상적으로 빌드되는데 공식
커널에서는 빌드되지 않는 것일까.

빌드 시 나오는 에러는 아래와 같다.

```

HOSTCC  scripts/mod/file2alias.o
scripts/mod/file2alias.c:47:3: error: typedef redefinition with different types ('struct uuid_t' vs '__darwin_uuid_t' (aka 'unsigned char [16]'))
} uuid_t;
  ^
/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/usr/include/sys/_types/_uuid_t.h:31:25: note: previous definition is here
typedef __darwin_uuid_t uuid_t;
						^
scripts/mod/file2alias.c:1305:42: error: array initializer must be an initializer list or string literal
		DEF_FIELD(symval, tee_client_device_id, uuid);
												^
2 errors generated.
```

이에 여기저기 뒤져보니 10달 전에 이미 [관련된
패치](https://gitce.net/mirrors/openwrt/commit/0b7ad6f7f061e0cd7a3f267b23d411cc2bd44e00)가
OpenWRT에 나와있었다. (역시 안될 리가 없다.)

```
diff --git a/scripts/mod/file2alias.c b/scripts/mod/file2alias.c
index c91eba751804..e756fd80b721 100644
--- a/scripts/mod/file2alias.c
+++ b/scripts/mod/file2alias.c
@@ -38,6 +38,9 @@ typedef struct {
	__u8 b[16];
 } guid_t;

+#ifdef __APPLE__
+#define uuid_t compat_uuid_t
+#endif
 /* backwards compatibility, don't use in new code */
 typedef struct {
	__u8 b[16];
--
2.21.1 (Apple Git-122.3)

```

맥이 가지고 있는 시스템 라이브러리의 uuid_t 대신 compat_uuid_t 를
사용하겠다는 건데 이렇게 define 매크로를 사용함으로써 typedef`으로
정의되는 타입명 자체를 바꿔버리는 것이 신선하게 다가왔다.

이제 file2alias.c 파일을 고친 뒤에 다시 빌드를 해보자. 커널 master
브랜치에서 문제 없이 빌드가 되는 것을 확인할 수 있다.
