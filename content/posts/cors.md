---
title: "CORS(Cross-Origin Resource Sharing)"
date: 2019-05-01T17:20:49+09:00
categories:
- Web
tags:
- cors
keywords:
- tech
---

## CORS(Cross-Origin Resource Sharing)

웹 보안 정책 중 `Same-Origin Policy`는 한 출처(Origin)에서 로드된 문서나 스크립트가 다른 출처 자원과 상호작용하지 못하도록 제약한다. 언급한 `출처(Origin)`는 두 페이지의 프로토콜, 호스트, 포트가 같으면 동일 출처로 간주한다.

하지만 이러한 보안 정책으로 인해 타 사이트로부터 받아오는 리소스나 웹 폰트, CDN 등의 사용에 문제가 되고 있어 `CORS(Cross-Origin Resource Sharing)`이라는 추가 정책이 나오게 되었다.

## CORS 요청

CORS 요청에는 Simple/Preflight, Credential/Non-Credential의 조합으로 총 4가지 요청이 존재한다. 브라우저가 요청 내용을 분석하여 4가지 방식 중 해당하는 방식으로 서버에 요청을 날리므로 프로그래머가 목적에 맞는 방식을 선택해 그 조건에 맞게 코딩해야 한다.

### Simple Requests

몇몇 요청(Request)들은 CORS preflight를 트리거하지 않는다. `MDN` 자료와 티맥스 출처자료에서는 이를 두고 `Simple Requests`라고 구분하지만 CORS를 정의한 실제 [Fetch](https://fetch.spec.whatwg.org/) 스펙에서는 Simple Requests라는 용어를 사용하지 않는다. **CORS preflight를 트리거 하지 않는 요청(편의상 MDN에서 'simple requests'라고 명명했던)은 아래의 조건들을 모두 만족하는 요청을 가리킨다.**

1. GET/POST/HEAD 메서드만을 사용해야 한다.
2. User Agent에 의해 자동으로 설정된 헤더, Fetch 스펙에서 "forbidden header name"이라고 정의된 헤더들을 제외하고 ["CORS-safelisted request-header"](https://fetch.spec.whatwg.org/#cors-safelisted-request-header)라고 Fetch 스펙에 정의된 아래의 헤더만이 직접적으로 요청 안에 설정될 수 있다.
   * Accept
   * Accept-Language
   * Content-Language
   * Content-Type
   * DPR
   * Downlink
   * Save-Data
   * Viewport-Width
   * Width
3. Content-Type이 아래 중 하나여야 한다.
    * application/x-www-form/urlencoded
    * multipart/form-data
    * text/plain (따로 지정하지 않을 시에 default)
4. Request 안에 `ReadableStream` 객체가 없어야 한다.
5. 요청 안에 있는 `XMLHttpRequestUpload` 객체에 대한 이벤트 리스너가 없어야 한다. (해당 객체는 XMLHttpRequest.upload 프로퍼티를 이용해 접근 가능하다.)

이러한 Simple Request 방식에서 클라이언트는 서버로 요청을 한 번 보내고, 마찬가지로 서버도 회신을 한 번 보내는 것으로 요청에 대한 응답이 종료된다.

아래는 Simple requests를 사용하는 자바스크립트 예제이다. 아래 코드가 `http://foo.example` 서버로부터 제공되어 `http://bar.other`라는 외부 도메인으로부터 리소스를 받아오려 한다는 상황을 가정해보자.

```javascript
var invocation = new XMLHttpRequest();
var url = 'http://bar.other/resources/public-data/';

function callOtherDomain() {
  if(invocation) {
    invocation.open('GET', url, true);
    invocation.onreadystatechange = handler;
    invocation.send();
  }
}
```

위 코드를 통해 웹 브라우저가 서버로 Request를 보내고 서버로부터 Response를 받는 과정을 아래와 같이 간략하게 나타낼 수 있다.

![An example of CORS Simple Request](/img/cors_simple_req.png)

이 때, 실제 Request와 Response가 어떤 식으로 오고 가는지 아래 텍스트를 보자. Request의 `Origin`, Response의 `Access-Control-Allow-Origin` 부분을 중심으로 살펴보자.

```http
GET /resources/public-data/ HTTP/1.1
Host: bar.other
User-Agent: Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.1b3pre) Gecko/20081130 Minefield/3.1b3pre
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: en-us,en;q=0.5
Accept-Encoding: gzip,deflate
Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7
Connection: keep-alive
Referer: http://foo.example/examples/access-control/simpleXSInvocation.html
Origin: http://foo.example
```
먼저, 위는 예제 코드가 서버로 보내는 Request를 나타내며 Origin 헤더부분은 컨텐츠가 `http://foo.example`로부터 오는 것이라고 서버에게 알리는 역할을 한다.

```http
HTTP/1.1 200 OK
Date: Mon, 01 Dec 2008 00:23:53 GMT
Server: Apache/2.0.61
Access-Control-Allow-Origin: *
Keep-Alive: timeout=2, max=100
Connection: Keep-Alive
Transfer-Encoding: chunked
Content-Type: application/xml
```
위는 서버가 클라이언트로 보내는 Response를 나타내며, `Access-Control-Allow-Origin: *`은 모든 도메인의 cross-site 방식으로부터 액세스가 가능하다고 클라이언트에게 알리는 역할을 한다. 하지만 만약 이 헤더가

```http
Access-Control-Allow-Origin: http://foo.example
```
처럼 왔다면 `http://foo.example`을 제외한 다른 도메인들에서는 cross-site 방식으로 해당 리소스에 접근할 수 없다는 것을 의미한다.

### Preflighted Requests

`Simple Requests`와 다르게 "preflighted" requests(사전 전달 요청)는 먼저 `OPTIONS` 메서드를 이용하여 HTTP request를 먼저 보내 실제 요청이 보내기에 안전한지 확인한다. 아래 조건들 중 하나라도 만족하면 `Preflighted Requests`로 간주한다.

1. Request가 아래 메서드를 사용한다.
    * PUT
    * DELETE
    * CONNECT
    * OPTIONS
    * TRACE
    * PATCH
2. `Simple requests`와 마찬가지로 User Agent의 자동 설정된 헤더를 제외하고, "CORS-safelisted request-header"를 포함한다.
    * Accept
    * Accept-Language
    * Content-Language
    * Content-Type
    * DPR
    * Downlink
    * Save-Data
    * Viewport-Width
    * Width
3. Content-Type 헤더 값이 아래를 제외한 다른 값인 경우
    * application/x-www-form-url
    * multipart/form-data
    * text/plain
4. Request 안에 있는 `XMLHttpRequestUpload` 객체에 한 개 이상의 이벤트 리스너가 등록된 경우
5. `ReadableStream`이 Request 안에서 사용된 경우

아래는 preflighted 요청을 위한 자바스크립트 예제이다.

```javascript
var invocation = new XMLHttpRequest();
var url = 'http://bar.other/resources/post-here/';
var body = '<?xml version="1.0"?><person><name>Arun</name></person>';

function callOtherDomain(){
  if(invocation)
    {
      invocation.open('POST', url, true);
      invocation.setRequestHeader('X-PINGOTHER', 'pingpong');
      invocation.setRequestHeader('Content-Type', 'application/xml');
      invocation.onreadystatechange = handler;
      invocation.send(body);
    }
}
```

위 예제 코드에서는 XML body를 보내기 위해 `POST` 방식을 사용하고 `X-PINGOTHER: pingpong`이라는 customized request 헤더를 사용했다. 또한, `application/xml` Content-Type을 사용함으로써 위에서 명시된 3가지 Content-Type 외에 해당하여 해당 request가 `preflighted` 타입이라는 것을 알 수 있다.

이제, 이 `preflighted request`가 서버로 보내질 때 어떤 식으로 요청과 응답이 오고가는지 아래 그림을 통해 개괄적으로 살펴보자.

![CORS Preflighted_request](/img/cors_preflight.png)

위 그림에서 주의해야할 것은 아래의 실제 REQUEST/REPONSE 코드에서 보겠지만 실제 POST request 안에는 `Access-Control-Request-*` 헤더가 없다는 점이다. 해당 헤더들은 모두 `OPTIONS` request에서만 필요하다. 또한, preflighted request의 경우 메인 Request를 보내기 전에 Preflighted Request를 한번 더 보낸다는 점이 주의하자.

아래는 위 다이어그램에 대한 실제 Request & Response 내용이다.

```http
OPTIONS /resources/post-here/ HTTP/1.1
Host: bar.other
User-Agent: Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.1b3pre) Gecko/20081130 Minefield/3.1b3pre
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: en-us,en;q=0.5
Accept-Encoding: gzip,deflate
Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7
Connection: keep-alive
Origin: http://foo.example
Access-Control-Request-Method: POST
Access-Control-Request-Headers: X-PINGOTHER, Content-Type


HTTP/1.1 200 OK
Date: Mon, 01 Dec 2008 01:15:39 GMT
Server: Apache/2.0.61 (Unix)
Access-Control-Allow-Origin: http://foo.example
Access-Control-Allow-Methods: POST, GET
Access-Control-Allow-Headers: X-PINGOTHER, Content-Type
Access-Control-Max-Age: 86400
Vary: Accept-Encoding, Origin
Content-Encoding: gzip
Content-Length: 0
Keep-Alive: timeout=2, max=100
Connection: Keep-Alive
Content-Type: text/plain
```

먼저, `preflighted request`와 그 응답에 대해 살펴보자. `Access-Control-Request-Method` 해더는 서버에게 실제 Request가 보내졌을 때 해당 Request의 메서드와 `X-PINGOTHER, Content-Type` 등의 custom header들을 함께 전송할 것이라고 미리 알린다. 서버는 클라이언트로부터 이러한 정보를 미리 `preflighted request`를 통해 전달받고 실제 request를 받을 것인지를 결정한 뒤 알려준다. 위에 나타난 Reponse 코드 중 유심해야할 부분은 다음과 같다.

```http
Access-Control-Allow-Origin: http://foo.example
Access-Control-Allow-Methods: POST, GET
Access-Control-Allow-Headers: X-PINGOTHER, Content-Type
Access-Control-Max-Age: 86400
```

서버는 preflighted request에 대한 응답을 통해 클라이언트로 사용 가능한 메서드와 헤더, 그리고 해당 리소스 접근을 위해 허용된 origin을 `http://foo.example`로 제한하여 보내주고 있다. 마지막으로 `Access-Control-Max-Age`는 해당 reponse가 또다른 preflight request를 보내지 않고 얼마 동안 캐시되어 있는지를 클라이언트에게 알려주는 역할을 한다. 여기서 86400은 86400초를 나타내어 24시간동안 cached response가 유효하다고 알린다.


```http
POST /resources/post-here/ HTTP/1.1
Host: bar.other
User-Agent: Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.1b3pre) Gecko/20081130 Minefield/3.1b3pre
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: en-us,en;q=0.5
Accept-Encoding: gzip,deflate
Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7
Connection: keep-alive
X-PINGOTHER: pingpong
Content-Type: text/xml; charset=UTF-8
Referer: http://foo.example/examples/preflightInvocation.html
Content-Length: 55
Origin: http://foo.example
Pragma: no-cache
Cache-Control: no-cache

<?xml version="1.0"?><person><name>Arun</name></person>


HTTP/1.1 200 OK
Date: Mon, 01 Dec 2008 01:15:40 GMT
Server: Apache/2.0.61 (Unix)
Access-Control-Allow-Origin: http://foo.example
Vary: Accept-Encoding, Origin
Content-Encoding: gzip
Content-Length: 235
Keep-Alive: timeout=2, max=99
Connection: Keep-Alive
Content-Type: text/plain

[Some GZIP'd payload]
```

### Requests with credentials
마지막으로 Credential, Non-Credential을 구분할 CORS Request 종류에 대해 기술한다.
이 "credentialed" requests는 HTTP Cookie와 HTTP Authentication information의 취약점에 대비하여 만들어진 request 타입이다. 기본으로 웹 브라우저는 cross-site XMLHttpRequest와 Fetch invocation에서 credential을 보내지 않는다.

아래 코드를 예로 들어보자. `http://bar.other/`로부터 받은 컨텐츠가 쿠키를 설정하는 리소스라고 가정하고, 아래 자바스크립트 코드가 `http://foo.example`내에서 동작하는 코드라고 생각하자.

```javascript
var invocation = new XMLHttpRequest();
var url = 'http://bar.other/resources/credentialed-content/';

function callOtherDomain(){
  if(invocation) {
    invocation.open('GET', url, true);
    invocation.withCredentials = true;
    invocation.onreadystatechange = handler;
    invocation.send();
  }
}
```
![CORS Credential Response](/img/cors-cred-req.png)

위처럼 새로 가져올 컨텐츠에서 캐시를 설정하는 등의 행위를 할 때 반드시 `withCredentials`를 설정해줘야 하며, 해당 헤더가 설정되었다면 웹 브라우저는 서버로부터 받은 response 안에 `Access-Control-Allow-Credentials: true`가 없는 경우는 모두 거절해버린다.

# 출처
* [CORS in MDN](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS#Preflighted_requests)
* [CORS(Cross-Origin Resource Sharing) 및 관련 내용 - Tmaxsoft](https://technet.tmaxsoft.com/download2.do?filePath=/nas/technet/technet/upload/kss/tnote/jeus/2016/07/&tempFileName=FILE-20160720-000007_160720170534_1.pdf&attFileSeq=FILE-20160720-000007&fileSeqNo=1&fileName=TN-JSDV-F0704001_CORS(Cross-Origin%20Resource%20Sharing)%20%EB%B0%8F%20%EA%B4%80%EB%A0%A8%20%EB%82%B4%EC%9A%A9.pdf)
