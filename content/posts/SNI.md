---
draft: true
title: "Server Name Indication(SNI)"
date: 2019-05-01T17:12:34+09:00
categories:
- web
tags:
- SNI
keywords:
- tech
---

# Server Name Indication
Server Name Indication(줄여서 SNI)는 SSL/TLS 기반의 HTTPS에 기반한 Name-based 가상 호스팅 환경에서 일어날 수 있는 문제점을 해결하기 위해 구현된 HTTPS의 Extension이다. 해당 문제점에 대해 구체적으로 설명하자면 Name-based 가상 호스팅 환경에서 클라이언트는 서버로 어떤 vhost를 사용할 것인지 Request 메시지에 같이 보낸다. 이 때, 사용하는 프로토콜이 HTTP가 아닌 HTTPS라면 서버는 클라이언트로 Server Hello 패킷을 보낼 때 패킷 내에 인증서 데이터를 함께 전송한다. 클라이언트가 다시 서버로 Client Hello를 보낼 때 클라이언트는 서버에서 보내준 인증서의 공개키로 암호화하여 패킷을 보내게 되는데 서버 입장에서는 클라이언트가 사용한 인증서가 어떤 가상 호스트에서 보낸 인증서인지 알 길이 없다. 이러한 문제를 해결하기 위해 Server Name Indication(SNI)라는 Extension을 사용하여 아래와 같이 문제를 해결할 수 있다.

## 서버에서 SNI 설정 방법(예시. Apache 사용)
SNI 설정을 위해서는 두 가지 방법이 있다. (설정 파일 변경 방법)

첫 번째는 하나의 가상 호스트만 정의하고 나머지는 SSLSNIMap을 통해 호스트 이름과 인증서 레이블을 맵핑하는 방법이다.
```apache
<virtualhost *:443>
  ServerName example.com
  SSLEnable SNI
  SSLServerCert default
  SSLSNIMap a.example.com sni1-rsa
  SSLSNIMap a.example.com sni1-ecc
  SSLSNIMap b.example.com sni2
</virtualhost>
```

두 번째는 가상호스트에 맵핑할 호스트명과 인증서 레이블을 각각 나누어 명시해주는 방법이다.
```apache
<virtualhost *:443>
  ServerName example.com
  SSLEnable SNI
</virtualhost>
<virtualhost *:443>
  ServerName a.example.com
  SSLEnable
  SSLServerCert sni1
</virtualhost>
<virtualhost *:443>
  ServerName b.example.com
  ServerAlias other.example.com
  SSLEnable
  SSLServerCert sni2
</virtualhost>
```

## 실제 SNI 패킷
```c
const unsigned char good_data_2[] = {
    // TLS record
    0x16, // Content Type: Handshake
    0x03, 0x01, // Version: TLS 1.0
    0x00, 0x6c, // Length (use for bounds checking)
        // Handshake
        0x01, // Handshake Type: Client Hello
        0x00, 0x00, 0x68, // Length (use for bounds checking)
        0x03, 0x03, // Version: TLS 1.2
        // Random (32 bytes fixed length)
        0xb6, 0xb2, 0x6a, 0xfb, 0x55, 0x5e, 0x03, 0xd5,
        0x65, 0xa3, 0x6a, 0xf0, 0x5e, 0xa5, 0x43, 0x02,
        0x93, 0xb9, 0x59, 0xa7, 0x54, 0xc3, 0xdd, 0x78,
        0x57, 0x58, 0x34, 0xc5, 0x82, 0xfd, 0x53, 0xd1,
        0x00, // Session ID Length (skip past this much)
        0x00, 0x04, // Cipher Suites Length (skip past this much)
            0x00, 0x01, // NULL-MD5
            0x00, 0xff, // RENEGOTIATION INFO SCSV
        0x01, // Compression Methods Length (skip past this much)
            0x00, // NULL
        0x00, 0x3b, // Extensions Length (use for bounds checking)
            // Extension
            0x00, 0x00, // Extension Type: Server Name (check extension type)
            0x00, 0x0e, // Length (use for bounds checking)

            /* SNI 설정 부분: 아래에서 "localhost"라고 서버의 이름을 직접 명시한다. */
            0x00, 0x0c, // Server Name Indication Length
                0x00, // Server Name Type: host_name (check server name type)
                0x00, 0x09, // Length (length of your data)
                // "localhost" (data your after)
                0x6c, 0x6f, 0x63, 0x61, 0x6c, 0x68, 0x6f, 0x73, 0x74,
            // Extension
            0x00, 0x0d, // Extension Type: Signature Algorithms (check extension type)
            0x00, 0x20, // Length (skip past since this is the wrong extension)
            // Data
            0x00, 0x1e, 0x06, 0x01, 0x06, 0x02, 0x06, 0x03,
            0x05, 0x01, 0x05, 0x02, 0x05, 0x03, 0x04, 0x01,
            0x04, 0x02, 0x04, 0x03, 0x03, 0x01, 0x03, 0x02,
            0x03, 0x03, 0x02, 0x01, 0x02, 0x02, 0x02, 0x03,
            // Extension
            0x00, 0x0f, // Extension Type: Heart Beat (check extension type)
            0x00, 0x01, // Length (skip past since this is the wrong extension)
            0x01 // Mode: Peer allows to send requests
};
```

# 출처
* [SNI(Server Name Indication) - IBM Knowledge Center](https://www.ibm.com/support/knowledgecenter/ko/SSEQTJ_9.0.0/com.ibm.websphere.ihs.doc/ihs/rihs_sni.html)
* [Extract Server Name Indication (SNI) from TLS client hello
](https://stackoverflow.com/questions/17832592/extract-server-name-indication-sni-from-tls-client-hello)
