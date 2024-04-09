---
draft: true
title: "RESTful 성숙도 모델, Richardson Maturity Model(RMM)"
date: 2019-05-01T18:38:22+09:00
categories:
- web
tags:
- RMM
- Restful
keywords:
- tech
---

<!-- toc -->

# 개요
이 문서는 진행하는 프로젝트에서 백엔드 서버에서 제공할 REST API를 어떻게 설계해야 하는가에 대해 공부하던 중 인터넷에서 찾은 문서를 정리한 것이다. 이 문서에서는 REST 소개부터 API 설계 방법, 그리고 설계한 API가 'RESTful' 이라는 형용사를 붙일 수 있는지 판단할 수 있는 'Richardson Maturity Model'이라는 성숙도 모델을 기술한다.

# REST 소개
이 절은 Microsoft의 [REST 소개](https://docs.microsoft.com/ko-kr/azure/architecture/best-practices/api-design)를 발췌하여 정리한 것이다.

REST는 하이퍼미디어 기반 분산 시스템을 구축하기 위한 아키텍처 스타일로서 프로토콜과는 관련이 없는 용어이다. (일각에서 REST와 SOAP를 비교하는 글들이 많아 언급하였다.) REST는 어떤 기본 프로토콜과도 독립적이며 HTTP에 연결될 필요가 없다. 그러나 대부분의 일반적인 REST 구현에서 응용 프로그램 프로토콜로 HTTP를 사용하고 이 지침에서는 HTTP를 위한 REST API 디자인에 중점을 둔다.

REST가 HTTP보다 우수한 주요 장점은 개방형 표준을 사용하므로 API 또는 클라이언트 응용 프로그램의 구현이 특정 구현에 바인딩되지 않는다는 점이다. 예를 들어 REST 웹 서비스는 ASP.NET으로 작성할 수 있으며, 클라이언트 응용 프로그램은 HTTP 요청을 생성하고 HTTP 응답을 구문 분석할 수 있는 모든 언어 또는 도구 집합을 사용할 수 있다.

아래는 HTTP를 사용하는 RESTful API의 몇 가지 디자인 원칙이며 잘 디자인된 웹 API는 아래에 언급되는 특성들을 지원해야 한다.

# HTTP기반 RESTful API 디자인 원칙

* REST API는 **리소스**를 중심으로 디자인되며 클라이언트에서 액세스할 수 있는 모든 종류의 개체, 데이터 또는 서비스가 리소스에 포함된다.
* 리소스마다 해당 리소스를 고유하게 식별하는 URI인 **식별자**가 있다. 예를 들어 특정 고객 주문의 URI는 아래와 같다.

```text
https://adventure-works.com/orders/1
```

* 클라이언트가 리소스의 **표현**을 교환하여 서비스와 상호 작용한다. 많은 Web API가 교환 형식으로 JSON을 사용한다. 예를 들어 위에 나열된 URI에 대한 GET 요청은 아래의 응답을 반환할 수 있다.

```json
{"orderID": 1, "orderValue":99, "productId": 1, "quantity": 1}
```

* REST API는 균일한 인터페이스를 사용하므로 클라이언트와 서비스 구현을 분리하는데 도움이 된다. HTTP 기반의 REST API의 경우 리소스에 표준 HTTP 동사 수행 작업을 사용하는 것이 균일한 인터페이스에 포함된다. 가장 일반적인 작업은 GET, POST, PUT, PATCH, DELETE 등이다.

* REST API는 상태 비저장 요청 모델을 사용한다. **HTTP 요청은 독립적이어야 하고 임의 순서대로 발생할 수 있으므로 요청 사이에 일시적인 상태 정보를 유지할 수 없다. 정보는 리소스 자체에만 저장되며 각 요청은 자동 작업이어야 한다.** 결국 이러한 클라이언트와 서버 간의 상태 유지 제약 조건 덕분에 웹 서비스를 확장하는데 유리한 면이 생기게 되었다. (둘 간에 상태를 처리할 필요가 없기 때문에) 하지만 웹 서비스가 백 엔드 데이터 저장소에 데이터를 쓰는 경우 규모 확장이 어려울 수 있다.

* REST API는 표현에 포함된 하이퍼미디어 링크에 따라 구동된다. 예를 들어 아래는 주문 요청을 JSON 형식으로 나타낸 것이다. 해당 요청에는 주문과 관련된 고객 정보를 가져오고 업데이트하는 링크를 포함하고 있다.

```json
{
  "orderId": 3,
  "productId": 2,
  "quantity": 4,
  "orderValue": 16,
  "links": [
    {"rel":"product", "href":"https://adventure-works.com/customers/3", "action":"GET"},
    {"rel":"product","href":"https://adventure-works.com/customers/3", "action":"PUT" }
  ]
}
```

# 잘 디자인된 웹 API가 지원해야 하는 특성
## 플랫폼 독립성
모든 클라이언트는 내부에서 API가 구현되는 방법에 관계없이 API를 호출할 수 있어야 한다. 이를 위해서는 표준 프로토콜을 사용해야 하고 클라이언트 및 웹 서비스가 교환할 데이터 형식에 동의할 수 있는 매커니즘이 있어야 한다.
## 서비스 진화
Web API는 클라이언트 **응용 프로그램과 독립적으로** 기능을 진화시키고 추가할 수 있어야 한다. API가 진화해도 기존 클라이언트 응용 프로그램은 수정 없이 계속 작동할 수 있어야 한다. 모든 기능은 클라이언트 응용 프로그램이 해당 기능을 완전히 이용할 수 있도록 검색이 가능하다.

# Richardson 성숙도 모델(Richardson Maturity Model)
REST 방식의 주요 요소들을 3개의 단계로 나눈 모델이며 이 모델은 리소스, HTTP 메서드(verbs), 하이퍼미디어 컨트롤을 도입한다.

![RMM](./images/RMM.png "Richardson Maturity Model")

## 레벨 0
이 모델의 시작점은 웹 매커니즘은 전혀 사용하지 않고 HTTP를 단순히 원격 통신을 위한 전송 시스템으로 사용하는 것이다. 여기서는 원격 프로시저 호출(Remote Precedure Invocation)에 기반한 원격 통신 매커니즘을 위한 터널링 매커니즘으로서 HTTP를 사용하는 것이다.

```plain
            |                             |
            |                             |
            o-----------------------------x AppointmentService
            | POST/OpenSlotRequest        |
            |                             |
            x-----------------------------o
            |       RESPONSE/OpenSlotList |
            |                             |
            |                             |
            o-----------------------------x AppointmentService
            | POST/RequestAppointment     |
            |                             |
            x-----------------------------o
            |       RESPONSE/Apointment   |
            |                             |
            |                             |
```

레벨 0 단계에서는 단순히 POX(Plain Old XML)을 주고 받는 단순한 RPC 스타일 시스템에 불과하다.

## 레벨 1: 리소스 사용
이 단계는 리소스를 도입하는 것이다. 레벨 0에서처럼 모든 요청을 단일 서비스 엔드포인트로 보내는 것이 아니라 개별 리소스와 통신하도록 설계하는 단계이다.


```plain
           |                                  |
           |                                  |
           | POST/OpenSlotRequest             |
           O----------------------------------X doctors/mjones
           |                                  |
           X----------------------------------O
           |          RESPONSE/OpenSlotList   |
           |                                  |
           |                                  |
           |                                  |
           | POST/RequestAppointment          |
           o----------------------------------X slots/1234
           |                                  |
           |                                  |
           X----------------------------------o
           |          RESPONSE/Appointment    |
           |                                  |
```

위 그림에서 첫 요청에서 해당 의사에 대한 리소스를 먼저 아래와 같이 POST로 요청하고 해당 결과 값을 받아올 것이다.

```http
POST /doctors/mjones HTTP/1.1
[various other headers]

<OpenSlotRequest date="2018-01-01" />
```

이 때, 중요한 것은 응답은 같은 기본 정보를 제공하지만 각 시간대는 이제 개별적으로 어드레싱이 가능한 리소스라는 점이다. 의사 정보를 요청하는 것과 마찬가지로 예약은 특정 시간대로 요청을 보내는 것이다.

```http
POST /slots/1234 HTTP/1.1
[various other headers]

<RequestAppointment>
    <patient id="jsmith" />
</RequestAppointment>
```

여기에 문제가 없다면 아래와 같은 응답을 받을 것이다.

```http
HTTP/1.1 200 OK
[various headers]

<appointment>
    <slot id="1234" doctor="mjones" start="1400" end="1450" />
    <patient id="jsmith" />
</appointment>
```

## 레벨 2: HTTP 메서드 사용(Verbs)
레벨 0, 레벨 1의 모든 통신에서 HTTP POST 메서드를 사용했지만 레벨 2에서는 HTTP 사용법에 가능한 가깝게 HTTP 메서드를 사용하여 API를 구현한다.

```plain

        |                                       |
        | GET/?date=20180101&status=open        |
        o---------------------------------------x doctors/mjones/slots
        |                                       |
        x---------------------------------------o
        |                   200 OK/OpenSlotList |
        |                                       |
        | POST/RequestAppointment               |
        o---------------------------------------x slots/1234
        |                                       |
        x---------------------------------------o
        |                           201 Created |
        |     Location: slots/1234/appointments |
        |                                       |
```

레벨 2는 HTTP 메서드와 HTTP 응답 코드의 사용을 도입한다. 여기에 일관성 문제가 생겨나는데 REST 옹호자들은 모든 HTTP 메서드 사용에 대해 언급하지만 웹의 존재에 의해 지지되는 핵심 요소들은 발생한 에러의 종류를 커뮤니케이션하기 위해 상태 코드를 사용하는 것과 안전한 오퍼레이션(GET 등)과 안전하지 않은 오퍼레이션 간의 분리를 제공하는 것이다.

## 레벨 3: 하이퍼미디어 컨트롤 도입
마지막 레벨은 HATEOAS(Hypertext As The Engine Of Application state)라는 약어로 종종 언급되는 것을 도입하는 단계이다. 예시에 적용하여 설명하자면, 예약을 하기 위해 필요한 요청을, 가능한 시간대 목록을 가져오면서 알 수 있는 디자인 방법이다.

먼저 아래의 다이어그램을 보자.

```plain
        |                                       |
        o---------------------------------------> doctors/mjones/slots
        | GET ?date=20180101&status=open        |
        |                                       |
        <---------------------------------------o
        | 200 OK OpenSlotList                   |
        | ...                                   |
        | <link rel="/linkrels/slot/book"       |
        |       url="/slots/1234"               |
        |                                       |
        |                                       |
        o--------------------------------------->
        | POST RequestAppointment               |
        |                                       |
        <---------------------------------------o
        | 201 Created                           |
        | Location: /slots/1234/appointment     |
        |                                       |
```

레벨 2에서 보냈던 GET과 동일한 요청으로 시작한다.

```http
GET /doctors/mjones/slots?date=20100104&status=open HTTP/1.1
Host: royalhope.nhs.uk
```

하지만 여기에 대한 응답은 새로운 요소를 가진다.
```http
HTTP/1.1 200 OK
[various headers]

<openSlotList>
 <slot id = "1234" doctor = "mjones" start = "1400" end = "1450">
            <link rel = "/linkrels/slot/book"
            uri = "/slots/1234"/>
 </slot>
 <slot id = "5678" doctor = "mjones" start = "1600" end = "1650">
            <link rel = "/linkrels/slot/book"
            uri = "/slots/5678"/>
 </slot>
</openSlotList>
```

이제 각 시간대는 예약하는 방법을 알려주는 URI를 포함한 링크 요소를 가진다.

하이퍼 미디어 컨트롤의 요점은 리소스로 다음에 무엇을 할 수 있는지, 그것을 하기 위해 다루어야 할 리소스의 URI를 함께 알려준다는 것이다. 우리가 예약 요청을 어디에 보낼지 알아야 하는 것이 아니라 응답 내에서 하이퍼미디어 컨트롤이 우리에게 그것을 어떻게 할지를 알려주는 것이다. 이러한 하이퍼미디어 컨트롤의 장점은 클라이언트 개발자가 프로토콜을 탐색할 수 있도록 돕는다. 링크는 개발자에게 다음에 무엇이 가능할지 힌트를 제공함과 동시에 새로운 기능이 추가된 경우에도 알릴 수 있다.


## 레벨의 의미
* 레벨 1은 큰 서비스 엔드포인트를 복수개의 리소스로 나누는 분할 & 정복(divide and conquer)을 사용해서 복잡성을 다루는 문제를 처리한다.
* 레벨 2는 불필요한 다양성을 제거하고, 동일한 방식으로 유사한 환경을 처리할 수 있도록 메소드의 표준 집합을 도입한다.
* 레벨 3은 프로토콜을 더 스스로 문서화할 수 있는 방법을 제공함으로써 발견가능성(discoverability)을 도입한다.

# 출처
* <https://docs.microsoft.com/ko-kr/azure/architecture/best-practices/api-design>
* <http://jinson.tistory.com/190>
