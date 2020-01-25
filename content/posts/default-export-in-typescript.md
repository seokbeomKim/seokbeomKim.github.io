---
title: "Named export와 Default export"
date: 2019-05-07T16:30:51+09:00
categories:
- Programming Languages
- typescript
tags:
- named export
- default export
keywords:
- tech
---

<!-- toc -->

# 개요
모듈 프로그래밍 기반인 자바스크립트는 모듈 방식은 처음 접했을 때
이해가 되지 않았다. 특히 default export와 named export 라는 export
방식과 자바스크립트 버전에 따른 문법 호환 때문에 모듈 export와 import,
require를 사용하는 코드를 이해하기 힘들었다.

이 문서에서는 타입스크립트를 이용하여 default, named export 각각을
구현한 뒤 `import`, `require` 키워드 각각을 이용하였을 때 레퍼런스
변수가 어떤 값을 가지고 있는지 확인한다.

# 직접 확인해보자
## 첫 번째 테스트
먼저 export할 테스트 클래스를 간단하게 구현한다.

``` javascript
// Named Export를 위한 클래스
export class NamedExportClass {
    test() {
        console.log("Named Export Class")
    }
}

// Default Export를 위한 클래스: 키워드 default를 갖는다.
export default class DefaultExportClass {
    test () {
        console.log("Default Export Class")
    }

}
```

이제 import하는 소스 코드를 구현해준뒤 `tsc` 명령어를 통해
타입스크립트 파일들을 자바스크립트 파일로 Trans-compile 한다.

``` javascript
import DefaultClass, {NamedExportClass}  from './exportObj'

const defaultObj = new DefaultClass()
const namedObj = new NamedExportClass()

defaultObj.test()
namedObj.test()

```

이 때, 눈여겨 봐야할 점은 `export default class ...`로 구현한 클래스의
이름을 DefaultExportClass가 아닌 `DefaultClass`(임의 이름)으로 정하여
import했다는 것이다. 소스 내의 이름 `DefaultClass` 이름 대신 다른
이름을 사용하여도 테스트 결과는 같다.

``` shell
➜  jsImport git:(master) ✗ tsc *.ts && node importTest
Default Export Class
Named Export Class
```

## 두 번째 테스트
이번에는 `import` 시에 `require` 키워드를 이용해서 그 결과를 확인해보자.

``` javascript
import constObj = require('./exportObj')
console.log(constObj)
```

테스트 결과는 아래와 같다.

``` text
{ __esModule: true,
  NamedExportClass: [Function: NamedExportClass],
  default: [Function: DefaultExportClass] }
```

즉, export 객체 자체를 반환하게 된다.

## 세 번째 테스트
그렇다면, 클래스가 아닌 객체를 `defaul export` 로 정의하면 어떻게
될까? 기존 코드에서 `new DefaultClass()`는 실행이 불가능한 코드가 되고
`DefaultClass` 자체가 객체를 가리키게 된다. 하지만 `require`를 이용해
가져온 `constObj`는 `export`를 가리키므로 아래와 같은 결과를 가지게 된다.

``` text
Default Export Class
Named Export Class
{ __esModule: true,
  NamedExportClass: [Function: NamedExportClass],
  DefaultExportClass: [Function: DefaultExportClass],
  default: DefaultExportClass {} }
```

# 정리
간단히 정리하면, `require`를 이용해 import를 할 경우에는 `export` 객체
자체를 가져오며, default export와 named export를 구분해서 제대로
사용하고자 한다면 `import`를 이용해 대괄호(`{ }`)를 이용해 사용한다.


# 출처
* https://medium.com/@etherealm/named-export-vs-default-export-in-es6-affb483a0910
