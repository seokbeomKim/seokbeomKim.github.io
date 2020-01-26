---
title: "서블릿 컨테이너와 서버와의 관계"
date: 2019-05-03T17:50:32+09:00
categories:
- web
tags:
- apache_httpd
- servlet_container
keywords:
- tech
---

<!-- toc -->

# 개요
아파치 서버에 톰캣(tomcat)을 이용하여 젠킨스와 같은 애플리케이션을
올려본 적은 있어도 직접 서블릿 컨테이너에서 사용할 수 있는
애플리케이션은 개발해 본 적이 없다. 때문에 서블릿이라는 용어 자체가
생소하고 웹 서버에서 이를 어떻게 관리하는지에 대해 궁금한 점을
중점으로 정리하고자 한다.

정리하고자 하는 질문은 아래와 같다.

1. <code>Apache</code>나 <code>Nginx</code>에서 서블릿 컨테이너로 어떤
   방식을 통해서 클라이언트 요청을 넘겨주는가?
1. 서블릿 컨테이너가 만들어진 이유는 무엇인가?
1. 애플리케이션의 서블릿은 서블릿 컨테이너가 가지고 있는 라이프사이클
   중 언제 추가되는가?
1. 애플리케이션이 가지는 서블릿은 서블릿 컨테이너에 어떤 형태로 추가되는가?
1. 클라이언트 요청 시 서블릿 컨테이너는 어떤 방법을 통해 적절한
   서블릿을 찾아내는가?

## 웹 서버, 웹 어플리케이션 서버에서 클라이언트 요청 방법
클라이언트 요청에 대한 서버의 처리 동작의 자세한 구현은 서버에 따라
달라진다. 하지만 웹 서버의 기본 작업은 관리자가 설정한 포트를
<code>LISTENING</code>하고 있다가 클라이언트로부터 요청이 들어오면 쓰레드풀로부터
쓰레드 하나를 반환받아 서블릿의 서비스 메서드를 호출하는 것이다.

![웹 서버 구조](/img/web-service-architecture.png)

### 처리 방법
1. 웹 서버는 브라우저(클라이언트)로부터 HTTP 요청을 받는다.
2. 웹 서버는 클라이언트의 요청을 WAS(Web Application Server)에 전달한다.
3. WAS는 관련된 서블릿을 메모리에 로드한다.
4. WAS는 web.xml을 참조하여 해당 서블릿에 대한 쓰레드를 생성하며, 이 때 쓰레드 풀을 사용한다.
5. <code>HttpServletRequest</code>와 <code>HttpServletResponse</code>
   객체를 생성하여 서블릿에 전달한다.
6. <code>doGet()</code> 또는 <code>doPost()</code> 메서드는 인자에
   맞게 생성된 적절한 동적 페이지를 Response 객체에 담아 WAS에
   전달한다.
7. WAS는 Response 객체를 HttpResponse 형태로 바꾸어 웹 서버에 전달한다.
8. 생성한 Thread를 종료하고 <code>HttpServletrequest</code>, <code>HttpServletresponse</code> 객체를 제거한다



## 서블릿 컨테이너에는 tomcat 외에 어떤 것들이 있는가?
서블릿 컨테이너 목록은 다음 [링크](https://en.wikipedia.org/wiki/Web_container)에서 확인할 수 있다.

## 서블릿 컨테이너가 필요한 이유는?
서블릿 컨테이너는 웹 컨테이너 또는 <code>Web Application
Server(WAS)</code> 라고도 불린다. WAS는 DB 조회나 다양한 로직 처리를
요구하는 동적 컨텐츠를 제공하기 위해 만들어진 애플리케이션
서버이다. 웹 서버의 기능들을 구조적으로 분리하여 처리하고자 하는
목적으로 제시되었다.

WAS가 필요한 이유는 웹 페이지는 정적 컨텐츠와 동적 컨텐츠가 모두
존재하는데 웹 서버만을 이용한다면, 사용자가 원하는 요청에 대한
결과값을 미리 모두 준비해 놓고 서비스를 해야한다. 따라서 WAS를 통해
요청에 맞는 데이터를 DB에서 가져와 비지니스 로직에 맞게 필요 시
생성하여 제공함으로써 자원을 효율적으로 사용할 수 있다.


# 출처
* https://gmlwjd9405.github.io/2018/10/27/webserver-vs-was.html
* https://www.javatpoint.com/container
