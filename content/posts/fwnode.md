---
title: "Fwnode"
date: 2023-03-19T17:45:39+09:00
tags:
- device-tree
- fwnode
categories:
- kernel
draft: false

---

fwnode에 대해서는 자료가 거의 없는 것 같다. 너무 쉬운 개념이라 없는 건지 관심이
없어서 그런 것인지는 모르겠으나 개인적으로는 단번에 이해되지가 않았고 참고할 수
있는 자료가 너무 없어서 아쉬웠다.

## 커밋 찾아보기
ChatGPT에게 fwnode를 설명해보았지만 제대로 대답해주지 않는다. ARM 공식 문서 내의
내용은 잘 설명해주는데 커널에 관련된 내용은 틀린 부분이 많다. 역시 이해하기
위해서는 최초 적용된 커밋을 보는게 제일 좋은 방법이다. 아래의 커밋을 살펴보면
어떤 동기를 가지고 코드를 작성했는지 이해할 수 있다.

-   [ce793486e23e0162a732c605189c8028e0910e86](https://github.com/torvalds/linux/commit/ce793486e23e0162a732c605189c8028e0910e86)
-   [8a0662d9ed2968e1186208336a8e1fab3fdfea63](https://github.com/torvalds/linux/commit/8a0662d9ed2968e1186208336a8e1fab3fdfea63)

최초 커밋에서 author은 아래와 같이 설명하고 있다.

> There are two benefits from that. First, the somewhat ugly and hackish struct
> acpi\_dev\_node can be dropped and, second, the same struct fwnode\_handle pointer
> can be used in the future to point to other (non-ACPI) firmware device node
> types.

## 디바이스 구성을 기술(표현)하는 방법: Device Tree

리눅스 커널에서는 디바이스 구성을 표현하기 위해 OF(Open Firmware)의 Device
Tree를 사용한다. 하지만 디바이스를 표현하는 방법에는 Device Tree 외에도
윈도우즈에서 사용되는 ACPI를 이용하는 방법이 있다. 이러한 방식에 대한 호환성을
제공하기 위해 리눅스 커널에서는 해당 부분을 추상화시킬 필요가 생겼고 이 때문에
도입된 것이 바로 fwnode이다.

ACPI가 아닌 경우에도 원하는 디바이스 표현 형태가 있다면, 해당 디바이스 노드를
올바르게 읽어올 수 있도록 fwnode 인터페이스만 구현해주면 된다. 리눅스 커널에서
디바이스의 property를 얻어오는 함수는 아래와 같이 fwnode를 이용하도록 구현되어
있다. 해당 디바이스가 어떤 device description method로 표현되어 있는지 상관없이
디바이스에 설정된 방식에 따라 원하는 프로퍼티를 가져올 수 있다.

```c
int device_property_read_string_array(struct device *dev, const char *propname,
				      const char **val, size_t nval)
{
	return fwnode_property_read_string_array(dev_fwnode(dev), propname, val,
						 nval);
}
```

## fwnode\_ops로 구분하는 디바이스 표현 방법
### Open Firmware인 경우

리눅스 커널에서 특이한 경우가 아니라면 기본적으로 `of_node_init`을 이용해
디바이스를 초기화하며 이 때 of\_fwnode\_ops를 사용하도록 설정된다.

```c
static inline void of_node_init(struct device_node *node)
{
#if defined(CONFIG_OF_KOBJ)
	kobject_init(&node->kobj, &of_node_ktype);
#endif
	fwnode_init(&node->fwnode, &of_fwnode_ops);
}
```

하지만 표현되어 있는 디바이스 노드를 of\_node가 아닌 acpi로서 아래와 같이
fwnode를 초기화할 수로 있고, swnode로서 초기화 할 수도 있다. 각 함수에서
호출되는 `fwnode_init()` 함수에 주목하자.

### Software Node (swnode)

```c
swnode_register(const struct software_node *node, struct swnode *parent,
		unsigned int allocated)
{
	struct swnode *swnode;
	int ret;

	/* ... */

	swnode->id = ret;
	swnode->node = node;
	swnode->parent = parent;
	swnode->kobj.kset = swnode_kset;
	fwnode_init(&swnode->fwnode, &software_node_ops);
	/* ... */
}
```

### ACPI

```c
void acpi_init_device_object(struct acpi_device *device, acpi_handle handle,
			     int type)
{
	INIT_LIST_HEAD(&device->pnp.ids);
	device->device_type = type;
	device->handle = handle;
	device->parent = acpi_bus_get_parent(handle);
	fwnode_init(&device->fwnode, &acpi_device_fwnode_ops);
	acpi_set_device_status(device, ACPI_STA_DEFAULT);
	acpi_device_get_busid(device);
	acpi_set_pnp_ids(handle, &device->pnp, type);
	acpi_init_properties(device);
	acpi_bus_get_flags(device);
	device->flags.match_driver = false;
	device->flags.initialized = true;
	device->flags.enumeration_by_parent =
		acpi_device_enumeration_by_parent(device);
	acpi_device_clear_enumerated(device);
	device_initialize(&device->dev);
	dev_set_uevent_suppress(&device->dev, true);
	acpi_init_coherency(device);
}
```

# V4L2 media framework와 fwnode의 관계

그렇다면, fwnode와 V4L2 media framework은 무슨 상관인가? V4L2 media framework의
v4l2-fwnode.h 파일을 보면 operation은 별도로 구현하지 않고 있다. 그 말은 V4L2
media framework에서 디바이스를 표현하는 방법을 새롭게 정의한 것이 아니라
단순하게 fwnode가 가지고 있는 기능을 이용한다는 것을 짐작할 수 있다.

v4l2-fwnode.h 파일에서 fwnode와 관련된 함수들을 살펴보면 아래와 같이 endpoint
개념이 나오는 것을 볼 수 있다.
```text
    v4l2_async_nf_parse_fwnode_endpoints
    v4l2_fwnode_connector_add_link
    v4l2_fwnode_connector_free
    v4l2_fwnode_connector_parse
    v4l2_fwnode_device_parse
    v4l2_fwnode_endpoint_alloc_parse
    v4l2_fwnode_endpoint_free
    v4l2_fwnode_endpoint_parse
    v4l2_fwnode_parse_link
    v4l2_fwnode_put_link
    fwnode_handle
    v4l2_async_notifier
    v4l2_async_subdev
```

fwnode\_endpoint를 아래와 같이 상속하여 v4l2\_fwnode\_endpoint로 정의해 사용하고
있는 것을 알 수 있다. 즉, fwnode의 graph 구성 기능을 이용하여
v4l2\_fwnode\_endpoint로서 미디어 파이프라인을 표현하기에 필요한 몇 가지 정보를 더
추가하고 있는 것일 뿐이다.

```c
struct v4l2_fwnode_endpoint {
	struct fwnode_endpoint base;
	/*
    	 * Fields below this line will be zeroed by
    	 * v4l2_fwnode_endpoint_parse()
    	 */
	enum v4l2_mbus_type bus_type;
	struct {
		struct v4l2_fwnode_bus_parallel parallel;
		struct v4l2_fwnode_bus_mipi_csi1 mipi_csi1;
		struct v4l2_fwnode_bus_mipi_csi2 mipi_csi2;
	} bus;
	u64 *link_frequencies;
	unsigned int nr_of_link_frequencies;
};
```

# 마치며
개인적으로 해석했을 때 fwnode는 device description methods 들의 abstraction data
structure이다. 끝.

# 참고
-   <https://events.static.linuxfound.org/sites/events/files/slides/unified_properties_API_0.pdf>

