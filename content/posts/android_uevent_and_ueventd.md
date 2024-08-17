---
title: "안드로이드의 uevent, ueventd"
date: 2020-01-30T23:34:30+09:00
categories:
- Android
tags:
- uevent
- ueventd
keywords:
- tech
toc: false
---

# 개요
디바이스 트리와 카메라 포팅에 관련된 디바이스 드라이버 코드를 적절하게 수정한 뒤에도 계속해서 디바이스가 정상적으로 동작하지 않았다. 로그 상으로는 디바이스 OPEN에 실패하는 것으로 나왔는데, 원인은 다른 곳에 있었다. ```ueventd.rc``` 파일을 수정하지 않아 관련된 디바이스 노드 파일에 대한 권한이 설정되지 않았던 것이 문제였다. 

본 포스팅에서는 `uevent`와 `ueventd`가 무엇인지 살펴보고 안드로이드 init 과정에서 어떻게 활용되는지 살펴보기로 한다.

여담으로 안드로이드의 uevent는 리눅스의 udev 와 비슷한 역할을 하면서도 조금 다르다. 리눅스의 일반적인 환경 구성이 devfs + udev 로 디바이스 노드 파일들을 관리한다면, 안드로이드는 `ueventd`를 이용하여 노드 파일들을 관리한다. 

# uevent & ueventd
리눅스에서는 디바이스 노드 파일을 생성할 수 있도록 `mknod` 유틸리티를 제공하지만 안드로이드에서는 보안 문제로 이를 제공하지 않는다. 때문에, 안드로이드의 init 프로세스는 아래의 두 가지 방식으로 디바이스 노드를 생성한다.

- hot plug: 시스템 동작 중 디바이스 장치가 삽입될 때 이에 대한 이벤트 처리로 `ueventd`를 거쳐 해당 장치의 디바이스 노드 파일을 동적으로 생성한다.
- cold plug: 미리 정의된 디바이스 정보를 바탕으로 init 프로세스가 실행될 때 일괄적으로 디바이스 노드 파일을 생성한다.

출처에 따르면 cold plug 방식에 대해서, `ueventd`가 실행되기 전에 디바이스 드라이버가 /sys 디렉토리 아래에 디바이스 노드를 생성하기 위한 정보들을 저장한 후, `ueventd`가 실행되면서 디바이스 노드를 생성하지 못한 디바이스 드라이버에 대해서 강제로 uevent 를 발생시켜 cold plug 처리를 한다고 설명하고 있다. 

# init process와 ueventd
안드로이드 init 과정에서 `ueventd`를 부른다. `ueventd` 에서는 내부적으로 아래의 `ueventd_main` 함수를 호출한다.

```c++
int ueventd_main(int argc, char **argv)
{
    struct pollfd ufd;
    int nr;
    char tmp[32];

    /* Prevent fire-and-forget children from becoming zombies.
    * If we should need to wait() for some children in the future
    * (as opposed to none right now), double-forking here instead
    * of ignoring SIGCHLD may be the better solution.
    */
    signal(SIGCHLD, SIG_IGN);

    open_devnull_stdio();
    klog_init();

    INFO(“starting ueventd\n”);

    /* Respect hardware passed in through the kernel cmd line. Here we will look
     * for androidboot.hardware param in kernel cmdline, and save its value in
     * hardware[]. */
    import_kernel_cmdline(0, import_kernel_nv);

    get_hardware_name(hardware, &revision);

    ueventd_parse_config_file(“/ueventd.rc”);

    snprintf(tmp, sizeof(tmp), “/ueventd.%s.rc”, hardware);
    ueventd_parse_config_file(tmp);

    device_init();

    ufd.events = POLLIN;
    ufd.fd = get_device_fd();

    while(1) {
        ufd.revents = 0;
        nr = poll(&ufd, 1, -1);
        if (nr <= 0)
            continue;
        if (ufd.revents == POLLIN)
               handle_device_fd();
    }
}
```

여기서 중요한 함수는 `ueventd_parse_config_file`와 `device_init`함수이다. `ueventd_parse_config_file`함수는 `ueventd.rc`파일과 `ueventd.%hardware%.rc` 파일을 읽어 디바이스 노드 파일을 만드는 정보를 얻는다. 이 파일에 저장되어 있는 정보는 device 이름, permission, gid, uid 이다. 아래는 업무에서 사용한 실제 ueventd.rc 파일로서 문제가 된 videosource에 대한 내용들이 추가되어야 했다.

```
/dev/switch_gpio_reverse	0666	system		system
#/dev/videosource* 로 가능
/dev/videosource0	0666	system		system
/dev/videosource1	0666	system		system
```
이 때, 별도로 저장되어 있지 않는 디바이스는 디폴트로 600, 0, 0이 세팅된다. `device_init` 함수는 `uevent_socket`을 열고 coldboot 함수를 실행한다.

여기서 연 소켓은 uevent를 보낼때 쓰이는 것이 아니라 나중에 발생한 uevent를 받을때 쓰인다.

```c++
void device_init(void)
{
    suseconds_t t0, t1;
    struct stat info;
    int fd;

    /* is 64K enough? udev uses 16MB! */
    device_fd = uevent_open_socket(64*1024, true);
    if(device_fd < 0)
        return;

    fcntl(device_fd, F_SETFD, FD_CLOEXEC);
    fcntl(device_fd, F_SETFL, O_NONBLOCK);

    if (stat(coldboot_done, &info) < 0) {
        t0 = get_usecs();
        coldboot(“/sys/class”);
        coldboot(“/sys/block”);
        coldboot(“/sys/devices”);
        t1 = get_usecs();
        fd = open(coldboot_done, O_WRONLY|O_CREAT, 0000);
        close(fd);
        log_event_print(“coldboot %ld uS\n”, ((long) (t1 – t0)));
    } else {
        log_event_print(“skipping coldboot, already done\n”);
    }
}
``` 

호출되는 coldboot는 내부적으로 `do_coldboot`를 호출한다.
```c++
static void do_coldboot(DIR *d)
{
    struct dirent *de;
    int dfd, fd;

    dfd = dirfd(d);

    fd = openat(dfd, “uevent”, O_WRONLY);
    if(fd >= 0) {
        write(fd, “add\n”, 4);
        close(fd);
        handle_device_fd();
    }

    while((de = readdir(d))) {
        DIR *d2;

        if(de->d_type != DT_DIR || de->d_name[0] == ‘.’)
            continue;

        fd = openat(dfd, de->d_name, O_RDONLY | O_DIRECTORY);
        if(fd < 0)
            continue;

        d2 = fdopendir(fd);
        if(d2 == 0)
            close(fd);
        else {
            do_coldboot(d2);
            closedir(d2);
        }
    }
}
```

디바이스 노드를 생성하지 못한 디바이스가 저장한 /sys 밑의 각각의 해당 폴더를 들어가 `uevent` 파일에 “add” 메시지를 써넣어 강제로 uevent를 발생시킨다. 그 후 `handle_device_fd` 함수를 통해 `uevent` 를 파싱해 디바이스 노드를 만든다. 이 과정에서 `ueventd_parse_config_file` 에서 얻어온 정보를 사용한다.

# 출처
- https://kshokd.wordpress.com/2012/08/29/init-%EA%B3%BC%EC%A0%95%EC%97%90%EC%84%9C-uevent%EC%99%80-ueventd%EC%9D%98-%ED%99%9C%EC%9A%A9/
