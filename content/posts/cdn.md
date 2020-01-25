---
title: "컨텐츠 전송 네트워크, CDN(Content Delivery Network)"
date: 2019-05-01T17:19:18+09:00
categories:
- web
tags:
- cdn
keywords:
- tech

---

# CDN(Content Delivery Network)
Content Delivery Network 또는 Content Distribution Network라고 불리는 네트워크는 컨텐츠를 효율적으로 전달하기 위해 여러 노드를 가진 네트워크에 데이터를 저장하여 제공하는 시스템을 말한다. 관련된 질문으로는 'CDN vs. Cache, 무엇이 더 효율적인가?'라는 것이 있다. CDN은 오늘날 텐스트, 그래픽, 스크립트, 미디어 파일, 소프트웨어, 문서 등의 다운로드가 가능한 객체들 뿐만 아니라 어플리케이션, 라이브 스트리밍 미디어 등의 다양한 컨텐츠들을 망라하여 제공하고 있다.

아래의 그림을 살펴보자.

![CDN 네트워크 차이점](/img/cdn_diff.png)

왼쪽의 그림은 컨텐츠가 End User들에게 직접 제공되는 반면에 오른쪽 그림은 End-User에서 가장 가까운 CDN 서버를 통해 간접적으로 전달된다. 즉, 사용자가 인터넷 상에서 가장 가까운 곳의 서버로 컨텐츠를 전송받아 트래픽이 특정 서버로 집중되지 않고 각 서버로 분산되도록 하는 기술이다. 때문에 외쪽 그림처럼 하나의 서버만 사용할 경우 모든 클라이언트의 요청이 한 곳으로 집중될 뿐만 아니라 클라이언트와 서버 위치와의 거리에 따라 네트워크 지연속도는 비례하기 때문에 응답이 늦어질 수 있다. 하지만 CDN을 경유하게 되면 지역적으로 먼 곳이 아닌 가까운 네트워크에 요청하기 때문에 물리적인 이유로 발생하는 네트워크 속도 지연과 같은 문제를 해결할 수 있다.

![CDN 네트워크](/img/cdn_overview.png)

## \<script\> 태그와 CDN
JQuery 를 사용할 때, 아래처럼 URL을 이용하여 JQuery를 로드하여 사용하거나 자신의 서버에 올려사용한다. 보통 아래와 같이 URL을 통해 로드하는 방식을 CDN 방식이라 일컫는데, 제공하고자 하는 컨텐츠(스크립트의 일부)를 외부 노드로부터 로드하는 방식이므로 CDN이라 할 수 있겠다.

```html
<script src="//ajax.googleapis.com/ajax/libs/jquery/1.8.2/jquery.min.js"></script>
```
