#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 매개변수 받기
CONTAINER_NAME=$1
HOST_PORT=$2

if [ -z "$CONTAINER_NAME" ] || [ -z "$HOST_PORT" ]; then
    echo -e "${RED}❌ 사용법: $0 [컨테이너명] [포트번호]${NC}"
    exit 1
fi

echo -e "${YELLOW}🔍 배포 후 상태 점검 시작: $CONTAINER_NAME (Port: $HOST_PORT)${NC}"
echo "------------------------------------------------------"

# 1. 컨테이너 실행 여부 확인
echo -n "1. 컨테이너 실행 상태: "
STATUS=$(docker inspect --format='{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "not_found")

if [ "$STATUS" == "running" ]; then
    echo -e "${GREEN}Running (정상)${NC}"
else
    echo -e "${RED}Failed ($STATUS)${NC}"
    docker logs --tail 20 "$CONTAINER_NAME"
    exit 1
fi

# 2. 포트 바인딩 확인
echo -n "2. 포트 리스닝 확인 ($HOST_PORT): "
PORT_CHECK=$(netstat -tuln | grep ":$HOST_PORT " || echo "")

if [ -n "$PORT_CHECK" ]; then
    echo -e "${GREEN}Listen 중 (정상)${NC}"
else
    echo -e "${RED}포트가 열리지 않음${NC}"
    exit 1
fi

# 3. 애플리케이션 응답 확인 (Health Check)
# 30초 동안 5초 간격으로 최대 6번 시도
echo -n "3. 서비스 응답 확인 (HTTP GET): "
MAX_RETRIES=6
COUNT=0
SUCCESS=false

while [ $COUNT -lt $MAX_RETRIES ]; do
    # localhost 대신 서버 IP가 필요한 경우 $(hostname -I | awk '{print $1}') 사용
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$HOST_PORT || echo "000")

    if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "302" ]; then
        echo -e "${GREEN}응답 성공 (HTTP $HTTP_CODE)${NC}"
        SUCCESS=true
        break
    else
        echo -n "."
        sleep 5
        COUNT=$((COUNT + 1))
    fi
done

if [ "$SUCCESS" = false ]; then
    echo -e "${RED}응답 없음 (최종 HTTP CODE: $HTTP_CODE)${NC}"
    echo "최근 로그 확인:"
    docker logs --tail 50 "$CONTAINER_NAME"
    exit 1
fi

# 4. 리소스 점유 확인 (CPU/MEM)
echo -n "4. 리소스 사용량: "
docker stats "$CONTAINER_NAME" --no-stream --format "CPU: {{.CPUPerc}}, MEM: {{.MemUsage}}"

# 5. 로그 내 에러 키워드 점검
echo -n "5. 최근 로그 에러 분석: "
ERROR_COUNT=$(docker logs --tail 100 "$CONTAINER_NAME" 2>&1 | grep -Ei "error|exception|fatal" | wc -l)

if [ "$ERROR_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}주의 ($ERROR_COUNT 개의 Error/Exception 발견)${NC}"
    docker logs --tail 20 "$CONTAINER_NAME" | grep -Ei "error|exception|fatal"
else
    echo -e "${GREEN}Clean (특이사항 없음)${NC}"
fi

echo "------------------------------------------------------"
echo -e "${GREEN}✅ 모든 체크 항목 통과! 배포 성공.${NC}"