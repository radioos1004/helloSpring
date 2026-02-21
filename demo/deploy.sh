#!/bin/bash

echo "=== [1] 시스템 및 환경 정보 ==="
hostname
whoami

echo "--- 도커 소켓 권한 확인 ---"
if [ -S /var/run/docker.sock ]; then
    ls -la /var/run/docker.sock
else
    echo "❌ 에러: /var/run/docker.sock 파일을 찾을 수 없습니다."
    exit 1
fi

# 에러 발생 시 즉시 중단
set -e

echo "=========================================="
echo "🚀 Spring Boot(Gradle) + Docker 배포 시작"
echo "=========================================="

# 변수 설정
APP_NAME="hellospring"
# 빌드 번호를 사용하여 고유한 버전 생성 (없으면 latest)
# VERSION="1.0.${BUILD_NUMBER:-latest}"
VERSION="latest"
IMAGE_NAME="${APP_NAME}:${VERSION}"

# 1. 작업 디렉토리 이동
if [ -d "demo" ]; then
    echo "📂 'demo' 폴더로 이동합니다."
    cd demo
fi

echo "📦 [Step 1] Gradle 빌드 시작 (Clean Build)..."
chmod +x ./gradlew
# clean을 반드시 포함하여 이전 빌드 기록을 삭제하고 새로 빌드합니다.
./gradlew clean bootJar -x test --no-daemon

echo "🏗️ [Step 2] Docker 이미지 빌드 중... ($IMAGE_NAME)"
# --no-cache 옵션을 추가하여 혹시 모를 빌드 캐시 문제를 방지할 수 있습니다.
docker build --no-cache -t $IMAGE_NAME .

# 관리 편의를 위해 최신 이미지를 latest 태그로 지정
docker tag $IMAGE_NAME $APP_NAME:latest

echo "✅ [Step 3] 이미지 빌드 완료"
docker images | grep $APP_NAME

echo "🚀 [Step 4] 기존 컨테이너 정리 및 새 컨테이너 실행"

# 1. 기존 컨테이너 중지 및 제거 (에러 무시)
docker stop my-spring-app 2>/dev/null || true
docker rm my-spring-app 2>/dev/null || true

# 2. 새로운 이미지로 컨테이너 실행
# ★중요★: hellospring:1.0.3 대신 변수($IMAGE_NAME)를 사용하여
# 방금 빌드한 최신 이미지가 실행되도록 수정했습니다.
docker run -d \
  -p 8081:8081 \
  --name my-spring-app \
  -e TZ=Asia/Seoul \
  $IMAGE_NAME

echo "------------------------------------------"
echo "🎉 배포 성공: $IMAGE_NAME"
echo "🌐 접속 주소: http://$(hostname -I | awk '{print $1}'):8081"
echo "------------------------------------------"