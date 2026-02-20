# helloSpring

```text
project-root/
├── docker-compose.yml      # ← 이 파일
└── demo/                   # ← Spring Boot 프로젝트 폴더
    ├── Dockerfile          # ← 제공된 Dockerfile
    ├── build/
    │   └── libs/
    │       └── *.jar       # ← 빌드된 JAR 파일
    └── src/
```
	
# 1. JAR 빌드 (demo 폴더에서)
cd demo
./gradlew bootJar

# 2. 컴포즈 실행 (project-root에서)
cd ..
podman-compose up -d
# 또는
docker-compose up -d

# 3. 로그 확인
podman-compose logs -f app

# 4. 중지 및 삭제
podman-compose down


# vmware podman / 서비스 등록
```text
VMware Linux VM
├── /opt/jenkins/              ← 데이터 저장 (영구)
│   ├── config.xml
│   └── jobs/
│
└── /home/사용자/               ← systemd 설정
    └── .config/systemd/user/
        └── jenkins.service    ← 부팅 시 /opt/jenkins 데이터로 컨테이너 시작
```