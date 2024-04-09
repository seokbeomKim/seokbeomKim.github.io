---
title: "라즈베리파이 네트워크 부팅 설정"
date: 2023-04-15T10:21:58+09:00
tags: 
- rpi
- nfs
- tftp
categories:
draft: false
---

# 네트워크 부팅 환경 설정

기본적으로 라즈베리파이의 경우 SD 카드에 부트에 필요한 파티션들을 저장한다. 이
때문에 커널이나 루트파일시스템의 수정사항이 있는 경우 매번 호스트에서 SD 카드에
관련된 파일을 넣어줘야 하는데 이것만큼 정말 번거로운 것이 없다.

필자는 라즈베리파이4를 기준으로 환경을 구성하였다. 본 페이지에서는 TFTP와
라즈베리파이의 PXE Boot을 지원하는 기본 부트로더를 이용해 커널 이미지를 로드하는
방법과 NFS를 이용하여 루트파일시스템을 로드하는 방법을 함께 기술한다.

## 네트워크 구성

일반적으로 부트로더에서 TFTP 클라이언트를 함께 제공한다. U-Boot 부트로더와
마찬가지로 라즈베리파이의 기본 부트로더 또한 내부적으로 TFTP 클라이언트를
포함하고 있어 부트로더에 관련된 설정만 추가해주면 된다. NFS의 경우 `mount`
명령어를 통해 하지만 그 전에 네트워크 구성에 대해 한 번 생각해봐야 한다.

![img](/img/raspberry-pi-netboot.drawio.png)

1.  TFTP 서버는 Host PC (Windows) 의 tftpd를 이용한다. WSL2에서 tftp 서버를
    구성해도 되지만 필자는 윈도우즈 호스트 PC에서 `tftpd64` 라는 프로그램을
    이용하기로 했다.
2.  NFS 서버는 WSL2에 구성하고 라즈베리파이에서 WSL2에 접근할 수 있도록 NFS에서
    사용하는 포트에 한하여 포트포워딩을 한다.


## TFTP 이용하여 커널 이미지 로드

TFTP를 이용해 커널 이미지를 로드하기 위해서는 아래의 작업 순서가 필요하다. 1번
내용은 `Raspberry Pi Imager` 라는 공식 유틸리티가 있고 굳이 설명을 하지 않아도
되기 때문에 따로 설명하지는 않겠다.

1.  SD 카드 이용해 기본 부트
2.  라즈베리파이의 부트로더 설정 변경
3.  SD 카드의 부트 파티션 복사
4.  tftp64 이용해 부트


### 2. 부트로더 설정 변경

아래에 설명하는 부트로더 설정 변경 방법은
<https://metebalci.com/blog/cardless-rpi4/> 에 따른 것이다. 찾아본 포스팅 중에
가장 정리가 잘 되어 있다. 포스팅 내 주요 내용을 정리하면, 아래의 순서로 부트로더
설정을 업데이트 한다.

1.  현재 부트로더 버전 확인
2.  pieeprom.bin 바이너리로부터 설정 추출
3.  설정 파일 내 TFTP 정보 추가
4.  변경한 설정 파일을 포함한 pieeprom.bin 재생성
5.  재생성한 pieeprom.bin으로 부트로더 업데이트

먼저 부트로더 버전을 확인해보자. `vcgencmd bootloader_version` 명령어를 이용하면
아래와 같이 현재 부트한 환경 기준으로 사용 중인 부트로더 버전을 확인할 수 있다.

```sh
pi@raspberrypi:~$ vcgencmd bootloader_version
2023/01/11 17:40:52
version 8ba17717fbcedd4c3b6d4bce7e50c7af4155cba9 (release)
timestamp 1673458852
update-time 1681394003
capabilities 0x0000007f
```

버전을 확인했으니 해당 날짜에 맞는 pieeprom을 홈 디렉토리로 복사하고 바이너리
파일로부터 설정을 추출한다. 만약 rpi-eeprom-config가 없다면 `rpi-eeprom` 패키지를
설치해줘야 한다.
```sh
$ pwd
/home/pi
$ cp /lib/firmware/raspberrypi/bootloader/default/pieeprom-2023-01-11.bin pieeprom.bin
$ rpi-eeprom-config pieeprom.bin > config.txt
```

출처에서는 `BOOT_ORDER` 를 강조하고 있는데, TFTP 환경으로 부팅해야 하므로 앞서
네트워크 구성에서 고려했던 것과 같이 config.txt 파일을 변경해준다.

```
[all]
BOOT_UART=1
WAKE_ON_GPIO=1
POWER_OFF_ON_HALT=0
TFTP_IP=192.168.0.5
CLIENT_IP=192.168.0.4
SUBNET=255.255.255.0
GATEWAY=
TFTP_PREFIX=0
BOOT_ORDER=0x21
TFTP_FILE_TIMEOUT=30000
```

설정이 끝났다. 이제 설정파일이 담긴 바이너리 파일을 생성하고 해당 파일로 업데이트 해주자.

```bash
$ rpi-eeprom-config --out pieeprom-out.bin --config config.txt pieeprom.bin
$ sudo rpi-eeprom-update -d -f ./pieeprom-out.bin
$ sudo reboot
```

### 3. SD 카드 부트 파티션 복사

이제 부트로더 설정은 끝났으니 SD 카드의 boot partition을 Host PC에 저장한다.
필자는 그냥 귀찮아서 tftpd64 디렉토리(`C:\Program Files\Tftpd64\rpi_boot`) 안에
넣어놓았다.

![img](/img/rpi_boot.png)

### 4. tftp64 이용해 tftpboot

이제 tftp64 프로그램에서 디렉토리를 설정해주고 라즈베리파이를 부팅해주면 커널
로드까지는 정상적으로 되는 것을 확인할 수 있다. tftp64 프로그램은 아래 링크에서
다운로드 받을 수 있다.

-   <https://bitbucket.org/phjounin/tftpd64/downloads/>

이제 tftp를 이용한 커널 이미지 로드 준비는 끝이 났다. SD 카드를 빼고 전원을
인가하면 커널 로드까지는 성공적으로 되는 것을 확인할 수 있다.

## NFS 이용하여 루트파일시스템 로드

커널 이미지를 성공적으로 로드한다고 해도 루트파일시스템 로드가 되지 않으니
부팅이 될 리가 없다. 필자는 WSL2(Ubuntu)에 NFS 서버를 구성해서 rootfs 마운트
시점에 NFS를 마운트하도록 구성하였다.

작업 순서는 아래와 같으며, 데비안 계열의 우분투 WSL 기준으로 설명하겠다.

1.  라즈베리파이 이미지 파일 (\*.img) 마운트 및 복사
2.  WSL2 내 nfs-server 설치 및 설정
3.  nfs-server 서비스 실행
4.  Windows 내 포트 포워딩 및 방화벽 설정

### 라즈베리파이 이미지 내 rootfs 파일 복사

먼저, 라즈베리파이 공식 사이트에서 os 이미지 파일을 다운로드 받는다. 본인은 현재
기준으로 lite version인 `2023-02-21-raspios-bullseye-arm64-lite.img` 파일을
다운로드 받았다. 그 후 아래와 같이 마운트를 하고 로컬 디렉토리에 내용을
복사한다.

```bash
$ sudo mount -o loop,offset=272629760 ./2023-02-21-raspios-bullseye-arm
64-lite.img /mnt/
$ mkdir /rpi
$ cp -ra /mnt/* /rpi
```

### NFS-Server 설치 및 설정

이제 rootfs는 준비되었으니 nfs-server를 설치할 차례이다. 필자는 라즈베리파이를
제외한 나머지 디렉토리는 필요하지 않기 때문에 rootdir을 /rpi로 설정하였다. 사용
환경에 따라 적절하게 설정해준다.

```bash
$ sudo apt install nfs-kernel-server
$ sudo vi /etc/nfs.conf
    
# 아래와 같이 [exports] 설정
[exports]
rootdir=/rpi
    
# ...
```

이제 `/etc/exports` 파일을 아래와 같이 설정해준다. `insecure` 옵션을 넣어주었는데
본인의 경우 이 설정을 제외하면 파일 퍼미션이 보이지 않아 함께 넣어주었다.

```bash
$ sudo vi /etc/exports
# ...
/       *(rw,sync,no_root_squash,insecure)
```

### nfs-server 서비스 실행

이제 서비스를 실행하고 `exportfs` 를 업데이트 해준다.

```bash
$ sudo service nfs-server restart
$ sudo export -arv
```

한 가지 발견한 문제는 윈도우즈에서 2049 포트가 포트포워딩이 되어 있을 경우 port
binding 에러로 인해 서비스 실행 에러가 생긴다는 점이다. 반드시 윈도우즈에서
포트포워딩 되어 있는 포트 중에 nfs 관련 포트가 없는지 확인하고 서비스를
실행한다.

```
PS C:\Users\chaox> netsh interface portproxy show all
    
Listen on ipv4:             Connect to ipv4:
    
Address         Port        Address         Port
--------------- ----------  --------------- ----------
0.0.0.0         3000        172.29.124.79   3000
0.0.0.0         2049        172.29.124.79   2049 <- 만약에 이 부분이 있다면 에러가 발생한다.
```

포트 포워딩 제거시에는 아래 명령어를 사용한다.

```
> netsh interface portproxy del v4tov4 listenport=2049 listenaddress=0.0.0.0
```

### 포트 포워딩 및 방화벽 설정

WSL2에서 서비스까지 정상적으로 실행되었다면 윈도우즈에서 아래와 같이
포트포워딩을 해준다. 그리고 정상적으로 2049 포트로 포트포워딩이 되어 있는지
확인한다. connectaddress는 `wsl hostname -I` 로 확인한 아이피 주소를 넣어준다.

```
> netsh interface portproxy add v4tov4 listenport=2049 listenaddress=0.0.0.0 connectport=2049 connectaddress=172.29.124.79
    
> netsh interface portproxy show all
    
Listen on ipv4:             Connect to ipv4:
    
Address         Port        Address         Port
--------------- ----------  --------------- ----------
0.0.0.0         3000        172.29.124.79   3000
0.0.0.0         2049        172.29.124.79   2049
```

이제 윈도우즈의 `Windows Defender Firewall with Advanced Security` 를 열어서
Inbound Rules와 Outbound Rules 각각 포트 2049에 대해 허용하도록 설정한다.

### 마무리

이제 마지막으로 앞서 복사해둔 경로 내 etc/fstab 을 아래와 같이 수정해준다.

```bash
$ sudo vi /rpi/etc/fstab
# ...
proc            /proc           proc    defaults          0       0
192.168.0.5:/   /               nfs     defaults,_netdav  0       1
```

마지막으로 부트 파티션으로 복사한 `cmdline.txt` 에 NFS를 로드할 수 있도록 변경해주자.

```text
console=serial0,115200 console=tty1 root=/dev/nfs nfsroot=192.168.0.5:/,nfsvers=4 ip=192.168.0.4 rw elevator=deadline fsck.repair=yes rootwait rootfstype=nfs
```

# 출처
-   <https://metebalci.com/blog/cardless-rpi4/>

