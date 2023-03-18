---
title: "자바의 중첩 클래스(Nested Class)"
date: 2019-05-03T20:38:14+09:00
categories:
- java
tags:
- nested class
keywords:
- tech
---

<!-- toc -->

# 개요

중첩 클래스(Nested Class)에 대해서 여러 사이트에서 설명해놓은 것이
있지만 잘못 설명되어 있는 부분도 있었다. 'Nested Class는 Inner Class와
같다.' 라는 식으로 기술해놓은 페이지가 많아 이번 기회에 확실하게
정리해놓고자 한다.

중첩 클래스(Nested Class)는 내부 클래스(Inner Class)와 같은 개념이
아니라 포함 관계이다. 중첩 클래스는 <code>static</code> 사용 여부에
따라, 정적 중첩 클래스(Static nested class)와 비정적 중첩
클래스(Non-static nested class)로 구분하며, 통상적으로 각각을
<code>정적 중첩 클래스(Static Nested Class)</code>, <code>내부
클래스(Inner Class)</code>라고 한다. 중첩 클래스와 내부 클래스를 같은
개념으로 혼용하는 용례가 많다는데 `static` 여부에 따라 구분되어 서로
다르다는 것을 반드시 알고 있자.

# 사용 이유
중첩 클래스를 사용하는 이유에 대한 오라클 페이지의 기술
내용이다. 개인적으로는 SRP나 OCP 등을 포함한 SOLID 원칙을 지키는데
오히려 악영향을 줄 수 있다고 판단해 중첩 클래스의 사용이 양면성이
있다고 판한다기 때문에 [해당
문서](https://docs.oracle.com/javase/tutorial/java/javaOO/nested.html)에서
제시하는 이유에 대해서는 동의를 하지 못하겠다.

어쨌든 문서 내에서 기술하는 중첩 클래스를 사용하는 이유는 아래와 같다.

1. 논리적으로 한 곳에 클래스들을 모아놓을 방법 중 하나로서 사용
2. 캡슐화 증가
3. 가독성 및 유지보수에 유리

# 정적 클래스와 내부 클래스

``` java
class OuterClass {

   // 스태틱 클래스
   public static class NestedStaticClass {
      public void printMessage () {
         System.out.println("Message from nested static class");
      }
   }

   // 내부 클래스(non-static nested class라고도 불린다.)
   public class InnerClass {
      public void display() {
         System.out.println("Message from non-static inner class");
      }
   }
}

```


# 스코프에 따른 내부 클래스 구분
내부 클래스는 스코프에 따라 아래와 같이 구분할 수 있다.

* Inner Class: 클래스 내부에 정의한 클래스이다.
* Method Local Inner Class: 메서드 내부에 정의한 클래스이다.
* Anonymous Inner Class: 익명 클래스를 이용하여 정의한
  클래스이다. 보통 인터페이스를 구현한 클래스를 메서드 인자로 넘김과
  동시에 정의할 때 사용한다.

``` java
...
// 익명 내부 클래스 사용 예
public returnValue () {
    return new IAInterface({

    @Override
    public methodA () {
       ...
    }

    });
}

...
```

# 출처
* http://ccm3.net/archives/20638
* https://docs.oracle.com/javase/tutorial/java/javaOO/nested.html
