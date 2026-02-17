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
