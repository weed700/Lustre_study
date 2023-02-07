# Lustre 파일시스템과 GPUDirect Storage 소개

&nbsp;
# 러스터 파일시스템

`러스터(Lustre)`는 분산 파일시스템의 한 유형인 병렬 파일시스템으로 주로 HPC의 대용량 파일시스템으로 사용되고 있습니다. 
러스터는 GNU GPL 정책의 일환으로 개방되어 있으며 소규모 클러스터 시스템부터 대규모 클러스터까지 사용되는 고성능 파일시스템입니다. 
러스터라는 이름의 유래는 `Linux`와 `Clustre`의 혼성어로 탄생하였습니다.

&nbsp;

* 러스터 파일시스템 아키텍처[^1]

![Lustre FS Architecture](/assets/Lustre_Architecture.PNG)
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
# mkfs.lustre --mgs --backfstype=zfs --mgsnode=100.100.100.104@o2ib --fsname=lustre --reformat mgspool/mgt /dev/sdb

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



### HSM(Hierarchical Storage Management)

`HSM`은 고가의 저장매체와 저가의 저장매체 간의 데이터를 자동으로 이동하는 데이터 저장 기술입니다.

* HSM 아키텍처[^2]

![HSM](/assets/HSM_Architecture.png)
<center>그림 2. HSM 아키텍처 </center>

&nbsp;

* 러스터 파일시스템을 하나 이상의 외부 스토리지 시스템에 연결할 수 있습니다.
* 파일을 읽기, 쓰기, 수정과 같이 파일에 접근하게 되면 HSM 스토리지에서 러스터 파일시스템으로 파일을 다시 가져옵니다.
* 파일을 HSM 스토리지에 복사하는 프로세스를 `아카이브(Archive)`라고 하고 아카이브가 완료되면 러스터 파일시스템에 존재하는 데이터를 삭제할 수 있습니다. 이것을 `릴리즈(Release)`라고 말합니다. HSM 스토리지에서 러스터 파일시스템으로 데이터를 반환하는 프로세스를 `복원(restore)`라 하고 여기서 말하는 복원과 아카이브는 `HSM Agent`라는 데몬이 필요합니다.
* `에이전트(Agent)`는 `copytool`이라는 유저 프로세스가 실행되어 러스터 파일시스템과 HSM 간의 파일 아카이브 및 복원을 관리합니다.
* `코디네이터(Coordinator)`는 러스터 파일시스템을 HSM 시스템에 바인딩하려면 각 파일시스템 MDT에서 코디네이터가 활성화되어야 합니다.

* HSM과 러스터 파일시스템간의 데이터 관리 유형은 5가지의 요청으로 이루어집니다.
    * `archive` : 러스터 파일시스템 파일에서 `HSM` 솔루션으로 데이터를 복사합니다.
    * `release` : 러스터 파일시스템에서 파일 데이터를 제거합니다.
    * `restore` : HSM 솔루션에서 해당 러스터 파일시스템으로 파일 데이터를 다시 복사합니다.
    * `remove` : HSM 솔루션에서 데이터 사본을 삭제합니다.
    * `cancel` : 진행 중이거나 보류 중인 요청을 삭제합니다.

&nbsp;

### PCC(Persistent Client Cache)

* PCC 아키텍처[^3]

![pcc](/assets/PCC_Architecture.png)
<center>그림 3. Persistent Client Cache </center>

&nbsp;

`PCC`는 러스터 클라이언트 측에서 로컬 캐시 그룹을 제공하는 프레임워크입니다. 각 클라이언트는 OST 대신 로컬 저장장치를 자체 캐시로 사용합니다. 로컬 파일시스템은 로컬 저장장치 안에 있는 캐시 데이터를 관리하는 데 사용됩니다. 캐시 된 입출력의 경우 로컬 파일시스템으로 전달되어 처리되고 일반 입출력은 OST로 전달됩니다.

PCC는 데이터 동기화를 위해 HSM 기술을 사용합니다. HSM `copytool`을 사용하여 로컬 캐시에서 OST로 파일을 복원합니다. 각 PCC에는 고유한 아카이브 번호로 실행되는 `copytool` 인스턴스가 있고 다른 러스터 클라이언트에서 접근하게 되면 데이터 동기화가 진행됩니다. PCC가 있는 클라이언트가 오프라인 될 시 캐시 된 데이터는 일시적으로 다른 클라이언트에서 접근할 수 없게 됩니다. 이후 PCC 클라이언트가 재부팅되고 `copytool`이 다시 동작하면 캐시 데이터에 다시 접근할 수 있습니다.

#### PCC 장/단점

* 장점

클라이언트에서 로컬 저장장치를 캐시로 이용하게 되면 네트워크 지연이 없고 다른 클라이언트에 대한 오버헤드가 없습니다. 또한, 로컬 저장장치를 입출력 속도가 빠른 SSD or NVMe SSD[^8]를 통해 좋은 성능을 낼 수 있습니다. SSD는 모든 종류의 SSD가 사용가능하며, 캐시 장치로 이용할 수 있습니다. PCC를 통해 작거나 임의의 입출력을 `OST`로 저장할 필요 없이 로컬 캐시 장치에 저장하여 사용하면 OST 용량의 부담을 줄일 수 있는 장점이 있습니다.

* 단점

클라이언트 로컬에 저장장치를 추가하면서 구성이 복잡해질 수 있습니다. 고속 저장장치를 통해 좋은 성능을 낼 수 있지만, 비용적인 문제가 있을 수 있습니다.

&nbsp;

### DoM(Data-On-MDT)

러스터 파일시스템은 현재 대용량 파일에 최적화되어 있습니다. 이로 인해 파일 크기가 너무 작은 단일 파일일 경우 성능이 크게 저하되는 문제가 있습니다. `DoM`은 작은 파일을 MDT에 저장하여 이러한 문제를 해결합니다. DoM을 이용해서 MDT에 작은 파일을 저장하였을 때 추가적으로 OST에 접근할 필요가 없어 작은 입출력에 대한 성능이 향상됩니다.

DoM은 두 가지 구성요소가 있습니다. 첫 번째는 `MDT` 컴포넌트 두 번째는 `OST stripe`로 구성됩니다. 기본적으로 `DoM`의 `MDT stripe` 크기는 1MB로 설정되어있습니다. 이를 변경하기 위해서는 다음과 같은 명령어를 사용합니다.

```console
// MDS 서버에서 실행

// DoM 스트라이프 크기를 확인
[root@MDS ~]# lctl get_param lod.*.dom_stripesize 

// DoM 스트라이프 크기를 2M로 변경
[root@MDS ~]# lctl get_param -P lod.*.dom_stripesize=2M 

// DoM 스트라이프 크기 설정을 설정 정보에 저장
// conf_param 옵션에 이어서 러스터 구성때 사용한 fsname과 데이터가 저장될 MDT의 번호 다음에 lod.dom_stripesize=0을 입력합니다.
// (<fsname>-MDT0000.lod.dom_stripesize=0)
[root@MDS ~]# lctl conf_param lustre-MDT0000.lod.dom_stripesize=0
```

다음은 `DoM`을 구성했을 때 예제 그림과 이를 구성하는 명령어 입니다.

#### DoM 구성 예시[^6]

![DoM](/assets/DoM.PNG)
<center>그림 6. Data-On-MDT </center>

&nbsp;
  
```console
[root@Client ~]# lfs setstripe <--component-end| -E end1> <--layout | -L> mdt [<--component-end| -E end2> [STRIPE_OPTIONS] ...] <filename>
ex) [root@Client ~]#  lfs setstripe -E 1M -L mdt -E -1 -S 4M -c -1 /mnt/lustre/domfile // -S는 스트라이프 크기, -c는 스트라이프 개수

//구성 확인
[root@Client ~]# lfs getstripe /mnt/lustre/domfile
test2_domfile
  lcm_layout_gen:    2
  lcm_mirror_count:  1
  lcm_entry_count:   2
    lcme_id:             1
    lcme_mirror_id:      0
    lcme_flags:          init
    lcme_extent.e_start: 0
    lcme_extent.e_end:   1048576
      lmm_stripe_count:  0
      lmm_stripe_size:   1048576
      lmm_pattern:       mdt
      lmm_layout_gen:    0
      lmm_stripe_offset: 0

    lcme_id:             2
    lcme_mirror_id:      0
    lcme_flags:          0
    lcme_extent.e_start: 1048576
    lcme_extent.e_end:   EOF
      lmm_stripe_count:  -1
      lmm_stripe_size:   4194304
      lmm_pattern:       raid0
      lmm_layout_gen:    0
      lmm_stripe_offset: -1
```

&nbsp;


## 각주
---
[^1]: https://wiki.lustre.org/Introduction_to_Lustre
[^2]: https://github.com/DDNStorage/lustre_manual_markdown/blob/master/03.15-Hierarchical%20Storage%20Management%20(HSM).md 
[^3]: https://wiki.lustre.org/images/0/04/LUG2018-Lustre_Persistent_Client_Cache-Xi.pdf
[^4]: https://wiki.lustre.org/images/b/b3/LUG2019-Lustre_Overstriping_Shared_Write_Performance-Farrell.pdf
[^5]: https://cug.org/proceedings/cug2019_proceedings/includes/files/pap136s2-file1.pdf
[^6]: https://github.com/DDNStorage/lustre_manual_markdown/blob/master/03.09-Data%20on%20MDT%20(DoM).md
[^7]: https://wiki.whamcloud.com/display/PUB/DNE+1+Remote+Directories+High+Level+Design
[^8]: https://tech.gluesys.com/blog/2021/03/03/NVMe_1.html
[^9]: https://en.wikipedia.org/wiki/Direct_memory_access
[^10]: https://wiki.lustre.org/Lustre_2.15.0_Changelog
[^11]: https://docs.nvidia.com/gpudirect-storage/release-notes/index.html#known-limitations

