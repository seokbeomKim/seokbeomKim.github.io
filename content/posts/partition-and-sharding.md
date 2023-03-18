---
title: "파티셔닝(Partitioning)과 샤딩(Sharding)"
date: 2019-05-01T20:29:02+09:00
categories:
- database
tags:
- partition
- shard
keywords:
- tech
---


<!-- toc -->
# 개요
데이터베이스에 관련된 문서를 보다보니 `Partition`, `Sharding`이라는 용어들이 등장하기 시작하기 시작했다. 이러한 것들은 말 그
대로 데이터베이스를 여러 개로 나누어 분산시키기 위한 기술 용어들인데 모두 서비스 크기 증가에 따른 DB 크기 증가, 성능 이슈에 따른 것이다.
 일명 VLDB(Very Large DBMS)라 불리는, DBMS 하나로 전체 데이터베이스를 다룰 수 없는 데이터베이스가 자연스럽게 등장하였고
 DBMS 한 개가 여러 개의 테이블을 관리하면서 성능 이슈도 생기게 되었는데 이를 해결하기 위한 것이 바로 `파티셔닝(partitioning)
과 샤딩(Sharding)`이다.

# 파티셔닝(Partitioning)
큰 테이블이나 인덱스를 관리하기 쉬운 크기로 분리하는 방법이다.

### 장점

1. 가용성(Availability): 물리적인 노드 분리에 따라 전체 DB 내의 데이터 손상 가능성이 줄어들고, 데이터 가용성이 향상된다.
2. 관리 용이성(Manageability): 큰 테이블을 제거하여 관리를 쉽게 할 수 있다.
3. 성능(Performance): 특정 DML(Data Manipuation Language)[^1]과 Query 성능을 향상시키며 대용량 데이터 `write` 환경에서 효율적이다.
- `insert`가 많은 OLTP(Online Transaction Processing)[^2] 시스템에서 insert 작업들을 로드 밸런싱을 통해 분산시켜 성능상의 이점이 있다.

### 단점

1. 테이블 간 `join` 비용 증가
2. 파티션 제약: 테이블과 인덱스를 별도로 파티션 할 수 없다.

## 파티셔닝 범위

1. Range Partitioning
- 연속적인 숫자나 날짜 기준으로 파티셔닝한다.
- 손쉬운 관리 기법 제공에 따라 관리 시간을 단축할 수 있다.
- 우편번호, 일별, 월별, 분기별 등의 데이터에 적합하다.

2. List Partitioning
- 특정 Partition에 저장될 데이터에 대한 명시적 제어가 가능하다.
- 분포도가 비슷하여 많은 SQL에서 해당 컬럼의 조건이 많이 들어오는 경우에 유용하다.
- Multi-Column Partition Key를 제공하기 힘들다.
- (한국, 일본, 중국 -> 아시아)(노르웨이, 스웨덴, 핀란드 -> 북유럽) 등의 예시 가능

3. Composite Partitioning
- Composite Partition은 파티션의 Sub-Partitioning을 말한다.
- 큰 파티션에 대한 I/O 요청을 여러 파티션으로 분산할 수 있다.
- Range Partitioning을 수행할 수 있는 컬럼이 있지만 파티셔닝을 수행한 결과의 파티션이 너무 커서 효과적으로 관리할 수 없을 때 유용하다.
- Range-List, Range-Hash

4. Hash Partitioning
- Partition Key의 해시값에 의한 파티셔닝(데이터 균등 분할 가능)
- Select시 조건과 무관하게 병렬 Degree 제공 (질의 성능 향상)
- 특정 데이터가 어느 Hash Partition에 있는지 판단 불가
- Hash Partition은 파티션을 위한 범위가 없는 데이터에 적합

## 파티셔닝 방법
### Horizontal Partitioning
- 데이터 개수를 기준으로 나누어 Partitioning 하는 방법이다. `Sharding`이 Horizontal Partitioning과 관련되는데, `같은 테이블 스키마를 가진 데이터를 데이터베이스 여러 개에 분산하여 저장하는 방법을 일컫는 용어이기 때문이다. 때문에 `Sharding`을 `Horizontal Partition`이라고 볼 수도 있다.

### Vertical Partitioning
- 테이블의 컬럼을 기준으로 데이터를 나눈다.
- 이미 정규화된 데이터를 분리하는 과정으로 생각해야 한다.
- 자주 사용하는 컬럼을 분리하여 성능 향상을 꾀할 수 있다.

# 샤딩, Sharding
DBMS 한 개로 처리할 수 있는 데는 한계가 있으므로 데이터베이스 여러 개를 사용하는 방식으로 데이터 조회 한계를 극복해야 한다. 이를 위해 분산 환경을 고려해 만들어진 데이터베이스를 이용하는 방법도 있지만 범위 검색에 취약하거나 JOIN 연산을 사용할 수 없는 등 기능에 제약이 많다. 따라서 상대적으로 풍부한 기능을 사용하면서 데이터 확장을 꾀할 수 있는 방법은 RDBMS를 샤딩(sharding)하여 사용하는 것이다. 계속 증가하는 데이터에 장애 없이 효과적으로 대응할 수 있어야 하고 서비스마다 다른 데이터 특성과 모델에 어떻게 대처할 것인가가 샤딩 플랫폼의 핵심이다.

## HP(Horizontal Partitioning)과 샤딩(Sharding) 비교
수평 분할(Horizontal Partitioning)이란 스키마가 같은 데이터를 두 개 이상의 테이블에 나누어 저장하는 디자인을 말한다. 가령 같은 주민 데이터를 처리하기 위해 스키마가 같은 '서현동주민 테이블'과 '정자동주민 테이블'을 사용하는 것을 말한다. 인덱스의 크기를 줄이고, 작업 동시성을 늘리기 위한 것이다. **보통 수평 분할을 한다고 했을 때는 하나의 데이터베이스 안에서 이루어지는 경우를 지칭한다.**

이에 비해, 샤딩은 물리적으로 다른 데이터베이스에 데이터를 수평 분할 방식으로 분산 저장하고 조회하는 방법을 말한다. '주민' 테이블이 여러 DB에 있을 때 서현동 주민에 대한 정보는 A DB에, 정자동 주민에 대한 정보는 B DB에 저장되도록 하는 방식이다. 여러 데이터베이스를 대상으로 작업해야 하기 때문에 경우에 따라서는 (JOIN 등) 기능에 제약이 있을 수 있고 일관성(consistency)과 복제(replication) 등에서 불리한 점이 많다. 예전의 샤딩은 애플리케이션 서버 레벨에서 구현하는 경우가 많았지만 최근에는 이를 플랫폼 차원에서 제공한다.

... (중략)

## 샤딩(Sharding)의 한계
샤딩의 대표적인 제약 사항은 아래와 같다.

* 두 개 이상의 샤드에 대한 JOIN 연산을 할 수 없다.
* auto increment 등은 샤드 별로 달라질 수 있다.
* last_insert_id() 값은 유효하지 않다.
* shard key column 값은 update하면 안된다.
* 하나의 트랜잭션에서 두 개 이상의 샤드에 접근할 수 없다.

따라서, 샤딩을 사용할 때는 위와 같은 제약 사항에 문제가 되지 않도록 데이터 모델링을 하는 것이 중요하다.

# 출처
* <https://nesoy.github.io/articles/2018-05/Database-Shard>
* <https://nesoy.github.io/articles/2018-02/Database-Partitioning>
* <https://en.wikipedia.org/wiki/Shard_(database_architecture)>
* [Sharding & Query Off Loading](http://bcho.tistory.com/670)
* <https://d2.naver.com/helloworld/14822>

# 각주
[^1]: '데이터 조작어'라고 부르며 SELECT, INSERT, UPDATE, DELETE 등의 명령어가 여기에 포함된다. 그 외에 '데이터 정의어'(DDL: CREATE/ALTER/DROP/RENAME/TRUNCATE), 데이터 제어어(GRANT/REVOKE), 트랜잭션 제어어(TLC: COMMIT/ROLLBACK/SAVEPOINT) 등이 있다. 자세한 것은 <http://brownbears.tistory.com/180> 참고
[^2]: 컴퓨터 시스템을 사용하는 트랜잭션 데이터 관리를 온라인 트랜잭션 처리(OLTP)라고 한다. OLTP 시스템은 조직의 일상적인 작업에서 발생하는 비지니스 상호작용을 기록하고 이 데이터를 쿼리하여 유추할 수 있도록 지원한다.
