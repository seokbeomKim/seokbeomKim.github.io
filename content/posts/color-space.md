---
title: "색 공간(Color Space)"
date: 2020-01-26T16:39:36+09:00
categories:
- Computer Science
tags:
- rgb
- yuv
- colorspace
mathjax: true
toc: true
---

# 색 공간 포맷

업무 상에 사용되는 일반적인 색 인코딩 시스템은 RGB 와 YUV 이다. 그 중에서도 SoC의 각 컴포넌트에서 이미지 처리를 위해 기본으로 요구하는 포맷은 YUV 이다. YUV에는 서브샘플링 방법에 따라 YUV444, YUV422, YUV411, YUV420 등으로 세분화할 수 있는데 각 특징에 따라 실제 표현되는 색이 달라지므로 주의해야 한다.

색 포맷에 대한 비트 구성은 표준에 따르지 않고 각 플랫폼 환경에 따라 달라지므로 SoC 데이터시트를 참고하여 컴포넌트에서 어떻게 구성되는지 확인해야 한다.

# RGB

RGB의 대표적인 포맷으로는 `ARGB8888`, `RGB888` 등이 있다. 각 채널 별로 2 bytes 씩이다. R/G/B 각각의 색상 정보에 대한 모든 정보를 가지고 있기 때문에 색 표현에 있어서 정확하지만 픽셀 한 개를 위해 필요한 비트가 최소 24비트나 차지하기 때문에 데이터 전송 면에 있어서 YUV 포맷보다 비효율적이다.

## RGB 8 BITS

RGB 8비트는 모든 색상 중에서 256개만을 선택하여 사용하며 모든 색상을 한번에 다 표현하지 못하기 때문에 팔레트라는 개념을 사용한다. 8비트 색상 정보는 256개의 팔레트 정보를 가지고 있고, 1 바이트의 점을 표현하는데, 이 때 1 바이트에 해당하는 것을 인덱스 컬러라고 하며, 어떤 팔레트인지를 나타낸다.

## RGB 16 BITS

8비트 RGB와는 달리 팔레트 개념이 없으며 RGB 요소를 공평하게 갖기 위해 5 비트씩 구성하거나 G 색상에 6 비트를 할당하여 `RGB555`, `RGB565` 등으로 나뉜다.

## RGB 24 BITS

16비트 RGB에서 5비트씩 나눈 것을 8비트씩 나눈 포맷이다.

## RGB 32 BITS

Alpha 채널이 추가된 RGB 형식으로 ARGB8888, RGBA8888 등의 포맷이 있다.

# YUV

색상을 나타내기 위해 삼원색을 표현하는 RGB 방식과 달리 빛의 밝기를 나타내는 휘도(Y)와 색상 신호(U, V)로 표현하는 방식이다. 티비나 비디오 카메라에서 많이 사용하는 방식이며, 사람의 눈이 색상 신호보다 밝기 신호에 더 둔하다는 점을 고려하여 만든 색 공간이기에 실제 RGB 신호와 YUV 신호의 차이를 잘 느끼지 못한다.

YUV는 Packed format 과 Planar format 등으로 아래와 같이 나눌 수 있다.

- Packed format: Y와 UV가 섞여 macro pixel을 이루는 방식 (YUYV a.k.a. {YUY2, YUNV, V422}, UYVY a.k.a. {Y422, UYNV})

    ![Packed Format](/img/packed_format.png)

- Planar format: Y, UV가 각각의 다른 영역에 나뉘어 픽셀 정보를 이루는 방식 (YUV422, YUV420(NV12, NV21))

    ![Planar Format](/img/planar_format.png)

## RGB-to-YUV 변환

YUV 데이터는 일반적으로 RGB 데이터를 변환하여 얻을 수 있으며, 일반적인 변환 공식은 아래와 같다. 변환 공식은 영상 출력에 사용하는 표준 또는 포맷에 따라 달라질 수 있다. `BT.601`의 경우 아래와 같다.

$$
W_R = 0.299, \\\\
W_G = 1 - W_R - W_B = 0.587, \\\\
W_B = 0.114,\\\\
U_{max} = 0.436,\\\\
V_{max} = 0.615$$

이 때, RGB 채널 각각에 대한 가중치를 이용하여 Y, U, V 채널 값을 아래와 같이 구할 수 있다.

$$Y' = W_RR + W_GG + W_BB = 0.299R + 0.587G + 0.114B,\\\\U = U_{max}((B - Y')/(1 - W_R)) =~ 0.492 (B - Y'),\\\\V=V_{max}(R-Y')/(1-W_R) = 0.877(R-Y')$$

BT.809의 경우는 R과 B에 대한 가중치를 아래와 같이 갖는다.

$$W_R=0.2126, W_B=0.0722$$

### 일반적인 RGB-to-YUV 예제

출처에서 가져온 변환 예제로 사용하는 표준, 포맷, 환경에 따라 가중치를 다르게 하여 변환할 수 있다.

![RGB-to-YUV](/img/RGB-to-YUV.png)

## Sub-Sampling 에 따른 포맷

같은 YUV 포맷이라도 해도, 이를 다시 서브샘플링하여 압축함으로써 전송 효율을 높일 수 있다. 이 때, YUV 의 각 채널에 대한 기호로 아래와 같이 나타낸다.

$$Y: Y, \\\\U: P_B(orC_B)\\\\V:P_R(orC_R)$$

### YUV444

원본 YUV 색상으로서 Y가 4 바이트 사용될 때 U와 V 채널에도 각각 4바이트를 사용한다. 왼쪽에서 오른쪽으로 픽셀 배열이 있다고 가정했을 때, 세로로 표현한 픽셀 한 개를 구성하는 각 채널은 Y', Cb, Cr 모두 동일한 비율로 구성되어 있다. 메모리 상으로 살펴 보았을 때, `YCbCr, YCbCr, ...` 등이 된다.

![YUV444](/img/yuv444.png)

### YUV422

YUV444와 달리 Cb, Cr 채널에 대해 픽셀 두 개에 대한 Cb, Cr 정보를 한 개로 하여 서브샘플링한 것을 나타낸다. 즉, Y 값이 두 개 올 때 나머지 채널은 1개씩 오게 되어 결국 4:2:2 의 비율을 갖게 된다. 메모리 상으로 살펴 보았을 때, `YCbYCr, YCbYCr, ...` 등이 된다.

![YUV422](/img/yuv422.png)

### YUV411

이전까지 다뤘던 내용처럼 밝기 신호인 Y가 4바이트 올 때 U, V 신호가 각각 1바이트씩 위치한다.

![YUV411](/img/yuv411.png)

메모리 상으로 살펴보면 YYYCb, YYYCr, YYYCb, YYYCr, ... 등이 된다. 밝기에 비해 색상의 해상도가 `1/4`로 떨어진다.

### YUV420

안드로이드 카메라 클래스에서 제공하는 YUV 데이터 포맷이다. 12비트 데이터 포맷으로 4가지 종류 (YV12, NV12, IMC2, IMC4 등)가 존재하며, Y가 4개 오면 U와 V가 1바이트씩 위치하며 4개의 Y값이 U와 V값을 공유한다. YYYYCb, YYYYCr, YYYYCb , YYYYCr, ... 등의 메모리 구성을 갖는다.

# 출처

- [https://m.blog.naver.com/PostView.nhn?blogId=wndrlf2003&logNo=220253497246&proxyReferer=https%3A%2F%2Fwww.google.com%2F](https://m.blog.naver.com/PostView.nhn?blogId=wndrlf2003&logNo=220253497246&proxyReferer=https%3A%2F%2Fwww.google.com%2F)
- [https://en.wikipedia.org/wiki/YUV#Y′UV411_to_RGB888_conversion](https://en.wikipedia.org/wiki/YUV#Y%E2%80%B2UV411_to_RGB888_conversion)
- [https://imagej.tistory.com/150](https://imagej.tistory.com/150)
- [https://seoduckchan.tistory.com/entry/yuv-color](https://seoduckchan.tistory.com/entry/yuv-color)

