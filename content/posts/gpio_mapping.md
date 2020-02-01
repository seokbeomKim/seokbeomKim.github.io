---
title: "Gpio_mapping"
date: 2020-01-31T23:48:06+09:00
categories:
- kernel
- linux
tags:
- gpio
keywords:
- tech
---

# GPIO 맵핑하기
오늘은 gpio 맵핑을 위해 디바이스 트리를 이용하였지만 정상적으로 설정되지 않는 문제가 있었다. SoC에서 GPIO Enable 에 대한 것이 문제일 것이라 예상되지만, GPIO 맵핑하는 방법으로 디바이스 트리를 이용하는 것 외에 어떤 대안이 있는지 알아보고자 정리하고자 한다.

GPIO 데이터를 맵핑하여 사용할 수 있는 방법은 아래와 같이 세 가지 방법이 있다.

1. 디바이스 트리 이용 (최근 트렌드)
2. Legacy Board & Machine Specific Code에서 플랫폼 데이터로 정의
 - (출처에 따르면) GPIO 맵핑을 플랫폼 데이터에 등록하여 사용하는 경우는 많지 않고 단순하게 핀 번호로 사용하는 경우가 대부분이었다고 한다.
3. ACPI 펌웨어 테이블에 정의

# 디바이스 트리를 사용하는 GPIO 매핑
디바이스 노드 내부에 "gpio-controller" 속성이 있으면 GPIO Controller 노드를 의미한다.

## cell 개수
`#gpio-cells = <2>` 속성은 셀 데이터 2개를 사용한다는 것을 의미한다. 아래 예시에서는 gpio1, gpio2에 대해 각각 다음과 같이 해석 가능하다.

- gpio1 controller는 cell 2개를 사용하여 디바이스 드라이버가 인자 2개를 받아 처리한다.
- gpio2 controller는 cell 1개를 사용하여 디바이스 드라이버가 인자 1개를 받아 처리한다.
- 지정되지 않는 경우 2 cell 방식을 사용한다.

```
gpio1: gpio1 {
    gpio-controller;
    #gpio-cells = <2>;
};
gpio2: gpio2 {
    gpio-controller;
    #gpio-cells = <1>;
}
```

enable-gpios = <&gpio2 2>;
data-gpios = <&gpio1 12 0>, <&gpio1 13 0>, <&gpio1 14 0>, <&gpio1 15 0>;

## Pin control subsystem과의 연동
`pin control subsystem`과의 연동은 gpio controller 노드에서 "gpio-ranges" 속성을 사용한다.
"gpio-ranges" 속성이 가리키는 phandle은 연계된 pin controller 노드를 가리켜야 한다. 그리고 1~3개의 인자를 사용할 수 있으며, 배열 사용을 지원한다.

```
iomux: iomux@FF10601c {
        compatible = "abilis,tb10x-iomux";
        reg = <0xFF10601c 0x4>;
        pctl_gpio_a: pctl-gpio-a {
                abilis,function = "gpioa";
        };
        pctl_uart0: pctl-uart0 {
                abilis,function = "uart0";
        };
};
uart@FF100000 {
        compatible = "snps,dw-apb-uart";
        reg = <0xFF100000 0x100>;
        clock-frequency = <166666666>;
        interrupts = <25 1>;
        reg-shift = <2>;
        reg-io-width = <4>;
        pinctrl-names = "default";
        pinctrl-0 = <&pctl_uart0>;
};
gpioa: gpio@FF140000 {
        compatible = "abilis,tb10x-gpio";
        reg = <0xFF140000 0x1000>;
        gpio-controller;
        #gpio-cells = <2>;
        ngpios = <3>;
        gpio-ranges = <&iomux 0 0>;
        gpio-ranges-group-names = "gpioa";
};
```

# ACPI 펌웨어를 사용하는 GPIO 매핑
디바이스 트리를 사용하는 방법과 유사하게 ACPI 디스크립션을 사용하는 방법이 있다. ACPI 5.1에서 소개된 [[[_DSD (Device Specific Data)|https://www.kernel.org/doc/Documentation/acpi/gpio-properties.txt]]를 참고한다.

```
Device (FOO) {
    Name (_CRS, ResourceTemplate () {
        GpioIo (Exclusive, ..., IoRestrictionOutputOnly,
            "\\_SB.GPI0") {15} // red
        GpioIo (Exclusive, ..., IoRestrictionOutputOnly,
            "\\_SB.GPI0") {16} // green
        GpioIo (Exclusive, ..., IoRestrictionOutputOnly,
            "\\_SB.GPI0") {17} // blue
        GpioIo (Exclusive, ..., IoRestrictionOutputOnly,
            "\\_SB.GPI0") {1} // power
    })

    Name (_DSD, Package () {
        ToUUID("daffd814-6eba-4d8c-8a91-bc9bbf4aa301"),
        Package () {
            Package () {
                "led-gpios",
                Package () {
                    ^FOO, 0, 0, 1,
                    ^FOO, 1, 0, 1,
                    ^FOO, 2, 0, 1,
                }
            },
            Package () {
                "power-gpios",
                Package () {^FOO, 3, 0, 0},
            },
        }
    })    Name (_CRS, )
}
```

# Platform 데이터에 GPIO 맵핑 (deprecated)
일부 시스템에서 아래의 매크로 함수, API를 사용하여 플랫폼 데이터에 저장한 후, 이를 lookup 하여 사용하는데 지금은 사용하지 않는 방법이다.

```c++
GPIO_LOOKUP(chip_label, chip_hwnum, con_id, flag)
GPIO_LOOKUP_IDX(chip_label, chip_hwnum, con_id, idx, flags)
```

아래와 같이 GPIO Lookup Table을 정의한 후에 아래와 같이 사용할 수 있다.

```c++
struct gpiod_lookup_table gpios_table = {
    .dev_id = "foo.0",
    .table = {
        GPIO_LOOKUP_IDX("gpio.0", 15, "led", 0, GPIO_ACTIVE_HIGH),
        GPIO_LOOKUP_IDX("gpio.0", 16, "led", 1, GPIO_ACTIVE_HIGH),
        GPIO_LOOKUP_IDX("gpio.0", 17, "led", 2, GPIO_ACTIVE_HIGH),
        GPIO_LOOKUP("gpio.0", 1, "power", GPIO_ACTIVE_LOW),
        { },
    },
};

gpiod_add_lookup_table(&gpios_table);

struct gpio_desc *red, *green, *blue, *power;

red = gpiod_get_index(dev, "led", 0, GPIOD_OUT_HIGH);
green = gpiod_get_index(dev, "led", 1, GPIOD_OUT_HIGH);
blue = gpiod_get_index(dev, "led", 2, GPIOD_OUT_HIGH);
power = gpiod_get(dev, "power", GPIOD_OUT_HIGH);
```
# 출처
- http://jake.dothome.co.kr/gpio-3/