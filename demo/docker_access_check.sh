#!/bin/bash

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}   🐳 Jenkins Docker 접근 권한 진단 도구   ${NC}"
echo -e "${BLUE}==========================================${NC}"

# 1. 현재 실행 사용자 확인
CURRENT_USER=$(whoami)
echo -e "👤 현재 실행 사용자: ${YELLOW}$CURRENT_USER${NC}"

# 2. Docker 설치 여부 확인
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ 에러: Docker가 설치되어 있지 않거나 PATH에 없습니다.${NC}"
    exit 1
else
    echo -e "✅ Docker 설치 확인: ${GREEN}$(docker --version)${NC}"
fi

# 3. Docker 데몬 실행 상태 확인
if ! systemctl is-active --quiet docker; then
    echo -e "${RED}❌ 에러: Docker 데몬이 실행 중이 아닙니다.${NC}"
    echo -e "${YELLOW}💡 조치: sudo systemctl start docker 실행 필요${NC}"
    exit 1
else
    echo -e "✅ Docker 데몬 실행 중"
fi

# 4. /var/run/docker.sock 권한 확인
echo -n "🔑 Docker 소켓 접근 권한: "
if [ -r /var/run/docker.sock ] && [ -w /var/run/docker.sock ]; then
    echo -e "${GREEN}읽기/쓰기 가능 (정상)${NC}"
else
    echo -e "${RED}접근 불가 (Permission Denied)${NC}"
    echo -e "${YELLOW}💡 조치 1: sudo usermod -aG docker $CURRENT_USER 실행 후 Jenkins 재시작${NC}"
    echo -e "${YELLOW}💡 조치 2: sudo chmod 666 /var/run/docker.sock (임시 방편)${NC}"
fi

# 5. Docker 그룹 소속 여부 확인
echo -n "👥 그룹 확인: "
if id -nG "$CURRENT_USER" | grep -qw "docker"; then
    echo -e "${GREEN}$CURRENT_USER 사용자가 docker 그룹에 포함되어 있습니다.${NC}"
else
    echo -e "${RED}$CURRENT_USER 사용자가 docker 그룹에 없습니다.${NC}"
    echo -e "${YELLOW}💡 조치: sudo usermod -aG docker $CURRENT_USER 실행 필요${NC}"
fi

# 6. 실제 Docker 명령 실행 테스트
echo -n "🚀 Docker 명령 실행 테스트 (docker ps): "
if docker ps > /dev/null 2>&1; then
    echo -e "${GREEN}성공! Docker 명령을 실행할 수 있습니다.${NC}"
else
    echo -e "${RED}실패! 권한 문제로 Docker 명령을 수행할 수 없습니다.${NC}"
    echo -e "${BLUE}--- [해결 가이드] ---${NC}"
    echo -e "1. 서버 터미널에서 아래 명령을 실행하세요:"
    echo -e "   ${YELLOW}sudo usermod -aG docker jenkins${NC}"
    echo -e "2. Jenkins 서비스를 재시작하세요:"
    echo -e "   ${YELLOW}sudo systemctl restart jenkins${NC}"
    echo -e "---------------------"
    exit 1
fi

# 7. 디스크 용량 확인 (Docker 빌드 시 자주 발생하는 이슈)
echo -e "💾 디스크 잔여 용량 확인:"
df -h /var/lib/docker | awk 'NR==2 {print "   - 사용량: " $5 " (잔여: " $4 ")"}'

echo -e "${BLUE}==========================================${NC}"
echo -e "${GREEN}✅ Docker 환경 체크 완료: 배포를 진행할 수 있습니다.${NC}"
echo -e "${BLUE}==========================================${NC}"