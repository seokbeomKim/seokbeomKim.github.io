---
title: "Kobject"
date: 2020-01-28T22:25:50+09:00
categories:
- Linux
- Kernel
tags:
- kobject
keywords:
- tech
toc: false
---

디바이스 트리를 살펴보다 `kobject` 에 대한 내용이 언급되기 시작했다. 단순한 객체가 아니라 특수한 목적으로 사용될 것이라 예상되어 관련 내용을 찾아보았다.

```c++
 61 struct kobject {
 62         const char              *name;
 63         struct list_head        entry;
 64         struct kobject          *parent;
 65         struct kset             *kset;
 66         struct kobj_type        *ktype;
 67         struct kernfs_node      *sd;
 68         struct kref             kref;
 69 #ifdef CONFIG_DEBUG_KOBJECT_RELEASE
 70         struct delayed_work     release;
 71 #endif
 72         unsigned int state_initialized:1;
 73         unsigned int state_in_sysfs:1;
 74         unsigned int state_add_uevent_sent:1;
 75         unsigned int state_remove_uevent_sent:1;
 76         unsigned int uevent_suppress:1;
 77 };
```

커널 문서(https://www.kernel.org/doc/Documentation/kobject.txt)에 따르면 `kobjects`와 더불어 `ksets`, `ktypes` 에 대해 아래와 같이 기술하고 있다.

   > A kobject is an object of type struct kobject.  Kobjects have a name
   and a reference count.  A kobject also has a parent pointer (allowing
   objects to be arranged into hierarchies), a specific type, and,
   usually, a representation in the sysfs virtual filesystem.

   > Kobjects are generally not interesting on their own; instead, they are
   usually embedded within some other structure which contains the stuff
   the code is really interested in

   > A ktype is the type of object that embeds a kobject.  Every structure
   that embeds a kobject needs a corresponding ktype.  The ktype controls
   what happens to the kobject when it is created and destroyed.

   > A kset is a group of kobjects.  These kobjects can be of the same ktype
   or belong to different ktypes.  The kset is the basic container type for
   collections of kobjects. Ksets contain their own kobjects, but you can
   safely ignore that implementation detail as the kset core code handles
   this kobject automatically.

Kobject는 이름과 참조횟수를 가지고 있는 객체로서 자기 자신에 대해 관심을 가지는 것이 아니라 다른 구조체에 embedded 되어 관련 코드에서 필요로 하는 내용들을 저장하는 용도로 사용한다. kobjects 자체는 계층 구조로 구성할 수 있도록 부모 포인터를 가지며 특정 유형이나 sysfs 등에도 사용된다. 

ktype은 kobject에 대한 도메인(정의역)이라 생각하면 이해하기 쉽다. 서로 다른 값들로 구성할 수 있는 도메인은 그 값에 대한 타입 시스템으로 구성할 수 있으며 이러한 타입시스템에 대한 개념이 여기에도 그대로 묻어나는 것을 네이밍을 통해 단번에 알 수 있다.

kset은 kobject, 즉 단순한 집합이다. 때문에 서로 다른 ktype들을 가지고 있을 수도 있고 모두 같은 ktype들로 구성할 수도 있다.

정리하면, kobjects, ksets, ktypes 들을 이용하여 커널 내에서 객체를 이용한 작은 타입시스템이라 생각할 수 있다. Functional Programming 에서 얘기하는 타입시스템을 이해하고 있다면 개념적으로 단번에 이해가 가능할 것이라 생각된다. 개념적으로 타입시스템을 구성하고 이를 sysfs 와 같은 파일 시스템에 적용하여, 해당 서브시스템(?)이 가질 수 있는 데이터들에 대한 타입시스템을 추상화하여 일관성 있게 구현하기 위해 고민한 흔적들을 엿볼 수 있다.

알면 알수록, 모르는 게 정말 많다.

# 출처
- https://sonseungha.tistory.com/236