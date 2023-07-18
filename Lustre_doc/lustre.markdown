# Lustre 파일시스템

&nbsp;
# 러스터 파일시스템

`러스터(Lustre)`는 분산 파일시스템의 한 유형인 병렬 파일시스템으로 주로 HPC의 대용량 파일시스템으로 사용되고 있습니다. 
러스터는 GNU GPL 정책의 일환으로 개방되어 있으며 소규모 클러스터 시스템부터 대규모 클러스터까지 사용되는 고성능 파일시스템입니다. 
러스터라는 이름의 유래는 `Linux`와 `Clustre`의 혼성어로 탄생하였습니다.

&nbsp;

* 러스터 파일시스템 아키텍처[^1]

![Lustre FS Architecture](/Lustre_doc/assets/Lustre_Architecture.PNG)
<center>그림 1. 러스터 파일시스템 아키텍처 </center>

&nbsp;

위 [그림 1]은 러스터 아키텍처를 표현한 것으로 각각의 구성 요소와 역할은 다음과 같습니다. 

* MGS(Management Server)
    * 모든 러스터 파일시스템에 대한 구성 정보를 클러스터에 저장하고 이 정보를 다른 러스터 호스트에 제공합니다.

* MGT(Management Target)
    * 모든 러스터 노드에 대한 구성 정보는 `MGS`에 의해 `MGT`라는 저장장치에 기록됩니다.

* MDS(Metadata Server)
    * 러스터 파일시스템의 모든 네임 스페이스를 제공하여 파일시스템의 아이노드(inodes)를 저장합니다. 
    * 파일 열기 및 닫기, 파일 삭제 및 이름 변경, 네임 스페이스 조작 관리를 합니다. 
    * 러스터 파일시스템에서는 하나 이상의 `MDS`와 `MDT`가 존재합니다.

* MDT(Metadata Target)
    * `MDS`의 메타 데이터 정보를 지속적으로 유지하는데 사용되는 저장장치입니다.

* OSS(Object Storage Servers)
    * 하나 이상의 로컬 `OST`에 대한 파일  서비스 및 네트워크 요청 처리를 제공합니다. 

* OST(Object Storage Target)
    * `OSS` 호스트에 고르게 분산되어 성능의 균형을 유지하고 처리량을 최대화합니다.

* Lustre 클라이언트
    * 각 `클라이언트`는 여러 다른 러스터 파일시스템 인스턴스를 동시에 마운트 가능합니다.

* LNet(Lustre Networking)
    * 클라이언트가 파일시스템에 액세스하는데 사용하는 고속 데이터 네트워크 프로토콜입니다.

&nbsp;

다음으로는 러스터를 어떻게 구성하는지 알아보겠습니다. 먼저 러스터에는 백엔드 파일 시스템으로 ldiskfs, zfs 2가지를 사용합니다.
저희는 ZFS를 기반으로한 Lustre 구성에 대해 알아보겠습니다.

### Lustre 구성 요소 생성

* 러스터와 ZFS가 설치되어 있다는 가정하에 진행됩니다.
* 러스터가 설치된 이후 `zfs, lustre`모듈을 올립니다.
```console
# modprobe zfs
# modprobe Lustre
```

* 다음으로 러스터에서 사용하는 네트워크 프로토콜을 지정합니다.
```console
// lnet 서비스를 작동 시킵니다.
# systemctl start lnet
# systemctl enable lnet

// lnetctl 명령어를 통해 add net을 할 떄 --net은 o2ib or tcp 프로토콜을 가집니다. --if는 interface의 약자로 적용할 IP의 interface를 넣어줍니다.
# lnetctl net add --net o2ib --if ib0
// lnet이 적용됬는지 확인하는 명령어 입니다.
# lnetctl net show
// 적용된 lnet 정보는 재부팅시 사라지므로 /etc/lnet.conf에 저장해놓습니다.
# lnetctl net show --net o2ib0 > /etc/lnet.conf
```

* 다음으로 러스터는 구성 요소를 생성합니다. 
* 러스터는 `mkfs.lustre`명령어를 통해 MGT,MDT,OST를 생성할 수 있습니다.

```console
// MGS 설정과 MGT를 생성합니다. 
# mkfs.lustre --mgs --backfstype=zfs --fsname=lustre --reformat mgspool/mgt /dev/sdb

// MDT를 생성합니다.
# mkfs.lustre --mdt --backfstype=zfs --index=0 --mgsnode=100.100.100.104@o2ib --fsname=lustre --reformat lustre-mdt0/mdt0 /dev/sdc

// OST를 생성합니다. raidz2라는 ZFS의 레이드를 통해 여러개의 디스크를 묶을 수 있습니다.
# mkfs.lustre --ost --backfstype=zfs --index=0 --mgsnode=100.100.100.104@o2ib --fsname=lustre --reformat lustre-ost0/ost0 /dev/sdd
or
# mkfs.lustre --ost --backfstype=zfs --index=0 --mgsnode=100.100.100.104@o2ib --fsname=lustre --reformat lustre-ost1/ost1 raidz2 /dev/sd[e,f,g]

------------------------------------------------------------------------------------------------------------------------------------------------
// 구성 요소를 ZFS 명령어 으로만 구성할 수 있습니다. 다음과 같이 생성하게 되면 위와 똑같은 구성을 할 수 있습니다.
// zpool 생성
# zpool create -f -O canmount=off mgspool /dev/sdb
-f : 파일 시스템이 있을 경우 강제로
-O : 파일 시스템 속성 값 지정 할 때 사용되는 옵션

// zfs dataset  생성
# zfs create -o canmount=off mgspool/mgt
canmount=off : zfs mount -a 명령을 사용하여 파일 시스템을 마운트 할 수 없음

// ZFS 기본 속성 값 지정
# zfs set xattr=sa mgspool/mgt
# zfs set dnodesize=auto mgspool/mgt

// Lustre 속성 값 지정 
# zfs set lustre:mgsnode=192.168.9.5@tcp mgspool/mgt 
# zfs set lustre:flags=100 mgspool/mgt                                       // flag 값은 mount 될 때 변경 되는 듯, flag 처음 OST의 flag 값과 일치해야지 된다.
# zfs set lustre:fsname=lustre mgspool/mgt
# zfs set lustre:index=65535 mgspool/mgt                                     // MDT나 OST가 여러개 일 떄는 index 번호를 지정해준다.
# zfs set lustre:version=1 mgspool/mgt
# zfs set lustre:svname=MGS mgspool/mgt                                      // MDT, OST의 lustre:svname 속성은 lustre:OST0001, lustre:MDT0000 숫자 4자리는 인덱스 번호랑 같게 만들어야한다.
```


* 마지막으로 구성된 요소들을 마운트 해줍니다.

```console

// 구성요소 마운트
mount -t lustre mgspool/mgt /lustre/mgt
mount -t lustre lustre-mdt0/mdt0 /lustre/lustre_vol/mdt0
mount -t lustre lustre-ost0/ost0 /lustre/lustre_vol/ost0


//모든 구성요소가 마운트 되면 최종적으로 러스터를 마운트 합니다. (mount -t lustre <MGS_NID>:/<fsname> /<mount point>)
mount -t lustre 100.100.100.104@o2ib0:/lustre /mnt/client_lustre
```

&nbsp;

다음으로 러스터를 구성할 때 사용하는 명렁어에 대해 알아보겠습니다.

* 러스터의 최초의 상태는 Linear(선형)로 파일을 쓰게되면 한 OST에 먼저 들어가게됩니다.
* 러스터를 스트라이프 구성할 때는 기본적으로 현재 존재하는 OST와 1:1 매칭으로 계산하여 스트라이프 개수를 지정합니다.
```console
// lfs 명령어를 통해 현재 스트라이프 개수를 확인합니다.
# lfs getstripe /mnt/client_lustre

// lfs setstripe 명령어를 통해 스트라이프를 지정할 수 있고, -c 옵션으로 스트라이프 개수를 지정할 수 있습니다.
# lfs setstripe -c 3 /mnt/client_lustre
```

## 각주
---
[^1]: https://wiki.lustre.org/Introduction_to_Lustre
