#!/bin/bash

# [환경 설정] 에러 발생 시 즉시 중단
set -e

# ==========================================
# 기본값 설정 및 도움말
# ==========================================
usage() {
    echo "사용법: $0 -n [APP_NAME] -t [TYPE] -p [PORT] -d [DIR] -v [VERSION]"
    echo "옵션:"
    echo "  -n : 애플리케이션 이름 (예: hellospring, my-dotnet-app)"
    echo "  -t : 프로젝트 타입 (java-gradle, java-maven, dotnet)"
    echo "  -p : 호스트 포트 (예: 8080)"
    echo "  -d : 프로젝트 디렉토리 경로 (기본값: .)"
    echo "  -v : 버전 (기본값: latest)"
    exit 1
}

# 기본값
APP_DIR="."
VERSION="latest"
HOST_PORT="8080"
APP_TYPE="java-gradle"

# 매개변수 파싱
while getopts "n:t:p:d:v:" opt; do
    case "$opt" in
        n) APP_NAME=$OPTARG ;;
        t) APP_TYPE=$OPTARG ;;
        p) HOST_PORT=$OPTARG ;;
        d) APP_DIR=$OPTARG ;;
        v) VERSION=$OPTARG ;;
        *) usage ;;
    esac
done

# 필수 값 체크
if [ -z "$APP_NAME" ]; then
    echo "❌ 에러: -n (APP_NAME)은 필수 입력 사항입니다."
    usage
fi

IMAGE_NAME="${APP_NAME}:${VERSION}"
CONTAINER_NAME="container-${APP_NAME}"

echo "=== [1] 시스템 정보 확인 ==="
echo "호스트: $(hostname)"
echo "사용자: $(whoami)"
echo "대상 디렉토리: $APP_DIR"
echo "애플리케이션 타입: $APP_TYPE"

# 1. 작업 디렉토리 이동
cd "$APP_DIR"

echo "📦 [Step 1] 빌드 시작 ($APP_TYPE)..."
case "$APP_TYPE" in
    "java-gradle")
        chmod +x ./gradlew
        ./gradlew clean bootJar -x test --no-daemon
        ;;
    "java-maven")
        mvn clean package -DskipTests
        ;;
    "dotnet")
        dotnet publish -c Release -o ./publish
        ;;
    *)
        echo "❌ 에러: 지원하지 않는 타입입니다 ($APP_TYPE)"
        exit 1
    ;;
esac

echo "🏗️ [Step 2] Docker 이미지 빌드 ($IMAGE_NAME)"
docker build --no-cache -t "$IMAGE_NAME" .
docker tag "$IMAGE_NAME" "$APP_NAME:latest"

echo "🚀 [Step 3] 기존 컨테이너 정리"
docker stop "$CONTAINER_NAME" 2>/dev/null || true
docker rm "$CONTAINER_NAME" 2>/dev/null || true

echo "🚀 [Step 4] 새 컨테이너 실행 (Port: $HOST_PORT)"
# 컨테이너 내부 포트는 일반적으로 Java(8080/8081), .NET(80) 등 다르므로 확인 필요
# 여기서는 편의상 내부 포트도 변수화하거나 Dockerfile의 EXPOSE를 따름
# 예시에서는 내부 포트를 8080으로 가정하거나 추가 인자로 받을 수 있음
INNER_PORT=8080
if [ "$APP_TYPE" == "dotnet" ]; then INNER_PORT=80; fi

docker run -d \
  -p "${HOST_PORT}:${INNER_PORT}" \
  --name "$CONTAINER_NAME" \
  -e TZ=Asia/Seoul \
  "$IMAGE_NAME"

echo "------------------------------------------"
echo "🎉 배포 완료: $IMAGE_NAME"
echo "🌐 접속 주소: http://$(hostname -I | awk '{print $1}'):$HOST_PORT"
echo "------------------------------------------"