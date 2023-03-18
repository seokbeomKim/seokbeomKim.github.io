---
title: "HTTP와 HTTPS의 차이점"
date: 2019-05-01T16:53:27+09:00
categories:
- Web
tags:
- http
- https
---

# HTTP와 HTTPS의 차이점
HTTP와 HTTPS의 차이점은 그 용어에서부터 단번에 알아챌 수 있다. 바로 끝 글자 'S'가 나타내는 Secure라는 의미로부터 HTTP에 '어떤 것'을 추가하여 보안을 강화한 프로토콜이라는 것을 짐작할 수 있다. 여기서 중요한 것은 HTTP에 추가한'어떤 것'인데 이 것이 바로 TLS(SSL라고도 부름)가 되겠다. HTTPS를 이해하기 위해서는 TLS에 대해 알아야 하므로 이 문서에서는 TLS에 대한 기본적인 개념과 HTTPS가 등장하게 된 배경에 대한 설명으로 HTTP와 HTTPS의 차이점을 설명하도록 하겠다. 먼저, HTTP, HTTPS와 TLS 프로토콜부터 살펴보자.

## HTTP(HyperText Transfer Protocol)와 HTTPS(HyperText Transfer Protocol Secure)

### HTTP(HyperText Transfer Protocol)
HTTP는 웹 브라우저와 같은 클라이언트가 웹 서버에 요청하는 프로토콜 중
하나로서 암호화 되어 있지 않은 Plain 텍스트 형태의 메시지를 주고받도록
구현되어 있다. 때문에 클라이언트와 서버 간의 데이터를 가로챈다면 해당
내용을 읽을 수 있는 취약점을 가지고 있다.

### TLS(Transport Layer Security)
HTTPS를 설명하기에 앞서 TLS 프로토콜에 대한 설명이 필요하다. TLS
프로토콜은 데이터를 암호화해서 송수신하는 프로토콜로서 넷스케이프가
개발한 SSL에 기반한 기술이다. 기반 기술인 SSL은 넷스케이프에서 1995년
2.0 버전으로 처음 공개하였다(1.0은 애초에 공개되지도 않았다). 하지만
몇 가지 취약점들이 발견되면서 넷츠케이프는 1년 만인 1996년에 다시 SSL
3.0을 공개하였다. (SSL 2.0, SSL 3.0은 SSLv2, SSLv3으로 언급되기도
한다.) 그리고 1996년도 버전인 SSLv3을 기반으로 하여 1999년에 표준으로
공개한 것이 TLS 1.0이다. 즉, TLS 1.0은 SSL 3.1이라고 생각하면 이해하기
쉽다.

실제로 TLS 1.0과 SSL 3.0의 차이는 많지 않지만 중요한 점이 이 둘이
상호운용이 안된다는 점이다. 그렇다면 둘 중 어떤 것을 써야 하는가에
대한 질문이 나올 수 있는데, 여기에 대한 답은 'TLS를 사용해야
한다'이다. SSLv2와 SSLv3은 각각 2011년, 2015년 IETF에서 depcrecated
되었으며 매년 POODLE, DROWN과 같은 취약점이 발견되고 있다. 최근 웹
브라우저들은 특정 서버에서 이러한 deprecated된 프로토콜을 사용하고
있다면 알아서 보안 경고를 내보내도록 구현되어 있다.

이러한 가운데 대다수는 아니지만 여전히 많은 사람들이 TLS 대신에
SSL이라는 용어를 혼용해서 사용하고 있다. 이 때문에 많은 곳에서 TLS
대신 'SSL/TLS' 라고 표기하고 있는데 서버 설정 시에는 반드시 이 둘을
구분하여 deprecated된 SSL은 비활성화하고 TLS만 활성화하도록 해야한다.

### HTTPS
HTTPS의 S는 Over Secure Socket Layer의 약자이다. 즉, HTTP 프로토콜에서 보안이 강화된 버전(HTTP + TLS)으로 이해하면 간단하다. 때문에 클라이언트와 서버 간의 데이터를 중간에서 가로챈다고 해도 Plain 텍스트가 아니기 때문에 제3자가 곧바로 내용을 확인할 수 없다.

그렇다면 두 프로토콜의 차이점인 암호화 프로토콜인 TLS는 어떤 방식으로 이루어지는 것일까? 아래는 TLS 방식으로 클라이언트와 서버가 핸드쉐이킹하는 과정을 간략하게 설명한 것이다.

1. 클라이언트(웹 브라우저)가 웹 서버에 접속한다.
2. 서버는 클라이언트에 인증서를 제공한다.
3. 클라이언트는 서버로부터 받은 인증서가 신뢰할 수 있는 인증서인지 검증한다.
4. 인증서가 신뢰할 수 있다면, 클라이언트는 서버로 `pre master secret key` 값을 암호화하여 전송한다.
5. 서버는 클라이언트로부터 받은 `pre master secret key`을 복호화한다.
6. 클라이언트와 서버는 동일한 `pre master secret key`를 가지고 `master secret key`를 만들어 세션 키를 공유한다.

인증서란 무엇이고 클라이언트와 서버는 어떻게 서로 암호화/복호화를 할 수 있는 것일까? 이를 위해서는 공개키와 대칭키의 개념부터 알아야 한다. HTTPS 프로토콜에서 서버와 클라이언트 간의 주고받는 모든 데이터들이 공개키와 대칭키를 응용한 것들이기 때문이다.

## 공개키(Public-Key Cryptosystem)와 대칭키(Symmetric-Key Cryptosystem)
### 대칭키(Symmetric-Key Cryptosystem)
암호를 만드는 행위인 암호화를 할 때 사용하는 비밀번호를 키(key)라고 한다. 이 키에 따라 암호화 결과가 달라지기 때문에 키를 정확하게 알지 않는 한 복호화가 불가능하다. 쉽게 설명하면 동일한 키로 암호화 또는 복호화를 할 수 있으므로 어떤 값을 암호화 할 때 1234라는 값을 사용했다면 복호화를 할 때도 1234라는 값을 입력해야 한다는 것이다. 아래는 이러한 공개키를 실제로 사용하는 예시이다.

```bash
$ echo 'this is the plain text' > plaintext.txt
$ openssl enc -e -des3 -salt -in plaintext.txt -out ciphertext.bin
enter des-ede3-cbc encryption password:
Verifying - enter des-ede3-cbc encryption password:

$ openssl enc -d -des3 -in ciphertext.bin -out plaintext2.txt
enter des-ede3-cbc decryption password:

$ diff plaintext.txt plaintext2.txt # 서로 같음
$ # 두 파일의 차이점이 없음
```

### 공개키(Public-Key Cryptosystem)
대칭키 방식의 경우 키가 한 번 유출되면 키를 획득한 공격자가 암호 내용을 복호화할 수 있다는 취약점 때문에 노드 간에 온라인으로 키를 주고받기가 어렵다. 이러한 대칭키의 단점을 극복하기 위해서 만들어진 것이 바로 공개키이다.

공개키 방식은 공개키(public key)와 비공개키(private key, 개인키라고도 부름)로 구성된다. 여기서 중요한 특징은 비밀키로 암호화를 하면 공개키로 복호화할 수 있고 반대로 공개키로 암호화하면 비밀키로 복호화할 수 있다는 점이다. 공개키 방식에서 비공개키는 자신이 가지고 있고 타인에게는 공개키를 제공한다. 이로써 비공개키를 가지고 있는 쪽에서는 비공개키를 이용하여 데이터를 암호화하여 타인에게 전달하거나, 타인이 전달한 암호화된 데이터를 비공개키를 이용하여 복호화할 수 있다.

이러한 공개키의 특징은 서버 - 클라이언트 간의 '인증서'로서 활용될 수 있다.

1. 서버는 CA(Certificate Authority)라는 공인된 기관으로부터 비밀키를 발급받는다.
2. 클라이언트가 서버로 접속했을 때 서버는 발급받은 비밀키에 대한 공개키를 클라이언트로 전송한다.
3. 클라이언트는 서버로부터 받은 공개키를 가지고 CA라는 제 3자에게 전송하여 연결하고자 하는 서버가 신뢰할 수 있는 서버인지 검증한다.

이 과정에서 공개키가 유출된다면 공격자에 의해 데이터가 복호화될 위험이 있지만, 위의 인증 단계에서 서버가 비공개키를 이용해 암호화하는 이유가 데이터 보호가 아닌 신원 보장에 있기 때문에 문제되지 않는다. 이러한 '전자 서명'은 암호화된 데이터가 공개키를 가지고 복호화 할 수 있다는 특징을 활용해 데이터를 제공한 사람의 신원을 보장해준다.

#### 인증서
위에서 언급한 인증서의 역할은 클라이언트가 접속한 서버가 클라이언트가 의도한 서버가 맞는지를 보장하는 역할을 한다. 이 역할을 하는 민간 기업들이 있는데 이들을 CA(Certificate Authority) 또는 Root Certificate라고 부른다. 이들 CA 리스트는 브라우저 내부에 내장되어 있으며 브라우저가 미리 파악하고 있는 CA 리스트에 포함되어야만 공인된 인증 기관이 될 수 있다.

## TLS Handshake
이제 마지막으로 HTTPS에서 사용하는 SSL/TLS의 Handshake에 대해 살펴보자.

![TLS Handshake](/img/TLS handshake.svg)

1. 클라이언트가 서버에 접속한다. 이 단계를 `Client Hello`라고 한다. 이 단계에서 주고 받는 데이터는 아래와 같다.
 - 클라이언트 측에서 생성한 랜덤 데이터(Client's random values)
 - 클라이언트가 지원하는 암호화 방식들(Supported cipher suites): 클라이언트와 서버가 지원하는 암호화 방식이 서로 다를 수 있기 때문에 상호간에 어떤 암호화 방식을 사용할 것인지에 대한 협상을 해야 한다. 이 것을 위해 클라이언트는 서버로 자신이 사용할 수 있는 암호화 방식을 전송한다.
 - 세션 아이디: 이미 한 번 handshake를 했다면 비용을 절약하기 위해 기존 세션을 재활용하게 되는데 이 때 사용할 연결에 대한 식별자를 서버 측으로 전송한다.

2. 서버는 `Client Hello`에 대한 응답으로 `Server Hello`를 클라이언트로 전송한다. 이 단계에서의 송수신 데이터는 아래와 같다.
 - 서버가 생성한 랜덤 데이터(Server's random values)
 - 서버가 선택한 클라이언트의 암호화 방식
 - 인증서

3. 서버가 클라이언트로 `Server hello done` 메시지를 보낸다.
4. 클라이언트는 서버의 인증서가 CA에 의해서 발급된 것인지 확인하기 위해 클라이언트에 내장된 CA 리스트를 확인하고 리스트에 인증서가 없다면 경고 메시지를 출력한다.
5. 클라이언트는 서버로부터 받은 랜덤 데이터와 클라이언트가 생성한 랜덤 데이터를 조합하여 `pre master secret`을 생성한 후 인증서에 들어 있는 공개키로 암호화한 후 서버로 전송한다.
6. 서버는 클라이언트로부터 `pre master secret`을 수신하고 클라이언트와 서버 모두 공통으로 갖고 있는 `pre master secret`을 토대로 `master secret`과 `session keys`를 생성한다.
7. 클라이언트는 `Change cipher spec` 알림을 서버로 보내 앞으로 새로운 세션 키를 이용하여 메세지 암호화/복호화를 할 것이라고 서버에 알린다.
8. 서버는 클라이언트로부터 `Change cipher spec` 수신한다. 그리고 record layer security state를 `session keys`를 이용하는 `비대칭 암호화 방식(symmetric encryption)`으로 변경한다. 변경이 완료되면 클라이언트에게 `Server finished` 메시지를 보낸다.
9. 이제 클라이언트와 서버는 세션키를 비대칭 방식으로 주고 받는 메시지를 암호화/복호화 할 수 있게 되었다.

### 세션 종료
이 후, 데이터 전송이 끝나면 SSL/TLS 통신이 끝났음을 서로에게 알리고 사용한 대칭키인 session keys를 폐기한다.

# 출처
1. [SSL vs. TLS - What's the Difference?](https://www.globalsign.com/en/blog/ssl-vs-tls-difference/)
2. [HTTPS와 SSL 인증서](https://opentutorials.org/course/228/4894)
3. [What's the difference between SSL, TLS, and HTTPS?](https://security.stackexchange.com/questions/5126/whats-the-difference-between-ssl-tls-and-https)
4. [TLS Handshake Protocol](https://docs.microsoft.com/en-us/windows/desktop/secauthn/tls-handshake-protocol)
