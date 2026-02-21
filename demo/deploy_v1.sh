#!/bin/bash

# [환경 설정] 에러 발생 시 즉시 중단
set -e

# ==========================================
# 기본값 설정 및 도움말
# ==========================================
usage() {
    echo "사용법: $0 -n [APP_NAME] -t [TYPE] -p [PORT] -d [DIR] -v [VERSION]"
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

if [ -z "$APP_NAME" ]; then
    echo "❌ 에러: -n (APP_NAME)은 필수 입력 사항입니다."
    usage
fi

IMAGE_NAME="${APP_NAME}:${VERSION}"
CONTAINER_NAME="container-${APP_NAME}"

echo "=== [1] 시스템 정보 확인 ==="
echo "대상 디렉토리: $APP_DIR"
echo "애플리케이션 타입: $APP_TYPE"
echo "대상 포트: $HOST_PORT"

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

# ============================================================
# [Step 3] 기존 컨테이너 및 포트 점유 정리 (수정된 부분)
# ============================================================
echo "🚀 [Step 3] 기존 컨테이너 및 포트 점유 정리"

# 1. 이름이 동일한 컨테이너가 있다면 제거
if [ "$(docker ps -aq -f name=^/${CONTAINER_NAME}$)" ]; then
    echo "  - 기존 컨테이너 이름($CONTAINER_NAME) 발견: 중지 및 제거 중..."
    docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
    docker rm "$CONTAINER_NAME" >/dev/null 2>&1 || true
fi

# 2. 이름은 다르지만 동일한 포트($HOST_PORT)를 사용하는 컨테이너가 있다면 제거
PORT_CONFLICT_CONTAINER=$(docker ps -q --filter "publish=$HOST_PORT")
if [ -n "$PORT_CONFLICT_CONTAINER" ]; then
    echo "  - 포트 $HOST_PORT 를 점유 중인 컨테이너($PORT_CONFLICT_CONTAINER) 발견: 제거 중..."
    docker stop "$PORT_CONFLICT_CONTAINER" >/dev/null 2>&1 || true
    docker rm "$PORT_CONFLICT_CONTAINER" >/dev/null 2>&1 || true
fi

# 3. (선택사항) 호스트 프로세스 자체가 포트를 쓰는 경우 (예: 로컬 실행 중인 Java)
# 만약 Docker 외부에서 실행 중인 프로세스까지 죽이고 싶다면 아래 주석을 해제하세요.
# fuser -k ${HOST_PORT}/tcp >/dev/null 2>&1 || true
# ============================================================

echo "🚀 [Step 4] 새 컨테이너 실행 (Port: $HOST_PORT)"
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