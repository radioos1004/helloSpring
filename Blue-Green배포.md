```text
helloSpring/
├── nginx/                        # 🆕 Nginx 설정 폴더
│   ├── nginx.conf                # Nginx 메인 설정
│   └── default.conf              # 리버스 프록시 및 스위칭 설정
├── demo/                         # 애플리케이션 소스 (기존과 동일)
│   ├── src/
│   ├── build.gradle
│   ├── Dockerfile
│   └── ...
├── docker-compose.yaml           # 🔄 Nginx와 App을 묶어서 관리할 설정
├── deploy.sh                     # 🔄 Blue/Green 로직이 추가된 배포 스크립트
├── check_deploy.sh               # 배포 상태 점검 (기존 활용)
└── docker_access_check.sh        # 권한 체크 (기존 활용)
```