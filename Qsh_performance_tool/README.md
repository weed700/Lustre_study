## lustre performace tool user guide

### config 파일 설정
 * 압축 해제한 디렉터리 들어가기
 * Config 디렉터리 들어가기
 * ./config.sh 실행
 * 공통으로 필요한 값 입력 ( ip, type, backfstype, fsname)
 * MGS, MDS, OSS, Client 순으로 입력( 같은 서버에 있을 경우 hostname을 동일하게 입력합니다. ex: MGS서버에 OST도 있을 경우)
 * 예를 들어 OST count는 OST 개수를 의미(한 서버에 OST가 1~n개 일 수있으니까) 만약 레이드로 묶어서 하나의 OST로 설       정한다면 OST count 는 1이 됩니다.
 * raid는 lustre에서 제공하는 것만 사용해야합니다.
 * device는 여러개 입력가능합니다. (스페이스바 기준으로 나눕니다.) 
 * 마지막으로 클라이언트 서버에서는 벤치마크 툴의 설정값을 정해줍니다.(현재 bonnie, fio만 테스트 가능)
 * 한개의 벤치마크 툴이 끝나고 변경하려면 클라이언트 .ini 파일을 열어값을 변경해줍니다.(ini 파일명은 [hostname].[몇번째 client인지에 대한 번호]_client_Config_Qsh.ini)

### 툴 실행
 * config 파일을 다 설정했으면 다시 이전 디렉터리로 돌아가서 ./Benchmark_Qsh.sh을 실행 시킵니다.
 * 위과정이 실행되면 lustre mount ~ benchmark test ~ umount 까지 동작됩니다. 

### 주의 할점
 * 각 서버는 ssh로 연결 가능해야하며, 비밀번호 없이 연결되어야 합니다. 
