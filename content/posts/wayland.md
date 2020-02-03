---
title: "Wayland과 Weston"
date: 2020-02-03T23:17:11+09:00
categories:
- linux
tags:
- wayland
- weston
toc: true
---

# 개요
직접적으로 연관된 업무는 아니지만 팀 내에서 `wayland`, `weston` 이라는
용어가 자주 들린다. 어렸을 적에 리눅스 데스크탑 환경에 관심이 많아
`X11` 기반으로 최소한의 작업 환경을 맞추고 `gnome`이나 `kde`, `xfce`가
아닌 `fluxbox`, `blackbox`, `i3`, `xmonad`, `enlightenment` 등을
이용해서 이런저런 시도를 해보았던 기억이 난다. 당시에는 그저 설치해서
사용하기에만 급급했지 실제로 업무에서 그러한 것들이 사용될 줄은 꿈에도
몰랐다.

이번 포스팅에서는 사내 위키의 내용을 출처로 하여, `wayland`,
`weston`에 대한 구조를 살펴보고 클라이언트 예제를 기술하고자 한다.

# Wayland
`wayland`는 display server protocol이다. 윈도우즈와 달리 리눅스는 GUI
환경에 대해서도 server - clients 개념으로 처음 구현되었고 X11 라는
이름으로 사용되었다. 그러나 복잡한 프로토콜과 라이브러리들로 인해
불필요한 호출이 많았고 이를 경량화하기 위한 노력의 결과가 바로
`wayland`이다.

`X11`에서 `wayland`로의 변화는 아래와 같다.

- `X11`은 독립적인 프로세스로서 동작하지만 `wayland`는 라이브러리
  형태로 구현되어 오버헤드가 감소
	 
- `X11`은 server, compositor로 구분되어 있지만 `wayland`는 server와
  compositor가 통합되어 두 컴포넌트 간의 불필요한 통신이 감소
  
- `X11`에서 렌더링을 서버가 담당하였지만, `Wayland`는 클라이언트가
  렌더링을 담당하여 서버와의 복잡도가 감소
  
- `X11`은 서버가 `client`, `compositor`, `kernel` 간의 모든 동작을
  중개하였지만, `Wayland`는 `server`가 `client`, `kernel`만 중개하여
  복잡도가 감소함
  
## Android에서 Wayland를 사용하지 않는 이유
Android Graphic에서는 `SurfaceFlinger`, `Gralloc` 솔루션을
사용한다. 각각에 대한 내용은 아래를 살펴보자.

### SurfaceFlinger
`SurfaceFlinger`는 사용자 프로세스나 앱에서 생성한 화면을 관리하고
화면의 위치나 표시 순서, 색상 등을 관리한다. 또한, 커널에 위치한
프레임 버퍼 드라이버와 연동하여 생성된 최종 이미지를 프레임 버퍼
드라이버를 통해 화면에 출력할 수 있도록 프레임 버퍼와 연동하는 역할을
한다.
![SurfaceFlinger](/img/surfaceflinger.jpg)

### Gralloc
Android에서 그래픽 버퍼의 할당과 해제를 담당한다.

## 윈도우즈와 맥에서 사용하지 않는 이유
윈도우즈는 DWM (Desktop Window Manager)를, 맥은 Quartz Compositor를 사용한다.

## Server/Client Model
`Wayland`는 여러 개의 인터페이스를 정의하여 사용할 수 있고 각각의
인터페이스는 `request`와 `event`로 구성된다.

![Wayland Architecture](/img/wayland-architecture.png)

1. kernel의 이벤트를 받으면 wayland compositor로 전달한다. kernel의
   드라이버를 재사용할 수 있다.
2. compositor는 여러 클라이언트 중에서 해당 이벤트를 수신할 client를
   결정한다.
3. client가 이벤트를 수신하면 렌더링이 발생한다. client는 업데이트 된
   화면을 표시하기 위해 compositor에 요청을 보낸다.
4. compositor는 client로부터 요청을 받은 후에 화면을 재구성한다. 그
   뒤, ioctl을 통해 KMS에게 재구성 된 화면을 전송한다.

# 그래픽 라이브러리 종류
출처에서는 모듈이라는 용어를 사용했는데 그래픽 라이브러리가 더 적절할
것이라 생각하여 그래픽 라이브러리로 기술하겠다. 이전에 보지 못했던
라이브러리들(clutter, SDL)이 있어 함께 정리하고자 한다.

## QT5
이전에는 qt4, qt5의 호환성으로 엄청나게 욕을 먹었었는데 최근에는
해결된 것으로 보인다. 리눅스, 안드로이드, 윈도우즈 등의 운영체제를
지원하며, qt의 대표적인 모듈은 아래와 같다.

- QtCore: 컨테이너 관리, 스레드 관리, 이벤트 관리 등을 제공하는 기본 라이브러리
- QtGui & QtWidgets: 데스크탑용 GUI 툴킷으로서 응용 프로그램을 위한 그래픽 구성 요소 제공
- QtMultimedia: 비디오, 카메라, 오디오 기능을 가진 클래스 제공
- QtNetwork: 네트워크 통신을 위한 클래스 제공
- QtSQL: ODBC, SQLite, MySQL 사용가능하도록 지원
- QtWayland: Wayland 기능 사용할 수 있도록 API 제공

## GTK+
GTK+ (GIMP Toolkit+)는 GUI를 위한 라이브러리로서 실제 사용해보면
알겠지만, 제공되는 프레임워크 API나 결과물의 코드가 더럽다. GTK에
대해서는 별도로 언급하지 않겠다.

## Clutter
인텔에 합병된 OpenedHand에서 C언어로 구현한 2D 그래픽 라이브러리로
객체 Actor와 이를 그리는 Canvas라는 추상화된 개념이 있다. OpenGL ES를
사용하기 때문에 데스크탑 뿐만 아니라 다양한 플랫폼에 적용할 수 있다.

## SDL (Simple DirectMedia Layer)
오디오, 키보드, 마우스, 조이스틱 등 하드웨어가 OpenGL 및 Direct3D에
대한 접근을 제공하도록 설계된 크로스 플랫폼 라이브러리이다. SDL은
윈도우즈용 게임을 리눅스로 쉽게 포팅하기 위한 라이브러리를 만들기 위해
개발되었고 현재는 멀티 플랫폼 상에서 게임 개발 및 포팅 목적으로 널리
이용되고 있다.

## EFL
Enlightenment Foundation Library로 Enlightenment에 코어 그래픽
라이브러리로 사용되는 라이브러리이다. 

# Weston
weston은 wayland compositor의 참조 구현(하드웨어 또는 소프트웨어
구현을 돕기 위해 제공하는 샘플 프로그램)이다. Desktop, 자동차,
키오스크, 셋톱박스 등을 위한 라이브러리를 제공하며 Wayland API에 대한
기본적인 내용을 담고 있기 때문에 기본적으로 창관리와 composite 기능을
갖고 있다.

## 기본 역할
Weston의 기본 역할은 아래와 같다.

- 윈도우들을 여러 계층으로 구분하여 관리한다.
- shell(윈도우 관리 규칙)을 이용해 출력되는 윈도우의 순서를 결정한다.
- 윈도우를 화면에 나타나게 하거나 위치를 옮기고 화면 크기 변경을
  관리한다.
  
# 출처
- Telechips, Graphic Framework
