# 1. 베이스 이미지 선택 (경량화된 JRE 이미지 사용)
FROM eclipse-temurin:21-jre-alpine

# 2. 컨테이너 내 작업 디렉토리 설정
WORKDIR /app

# 3. [핵심 수정] Gradle 빌드로 생성된 JAR 파일을 컨테이너로 복사
# 배포 스크립트가 'demo' 폴더 안에서 docker build를 실행하므로,
# 빌드 컨텍스트(기준 경로)는 'demo' 폴더 자체가 됩니다.
# 따라서 'demo/' 경로를 제외한 'build/libs/*.jar'가 올바른 경로입니다.
COPY build/libs/*.jar app.jar

# 4. 컨테이너가 외부에 노출할 포트 설정
EXPOSE 8080

# 5. 컨테이너가 시작될 때 실행할 명령어
# WORKDIR가 /app 이므로, JAR 파일의 전체 경로는 /app/app.jar 입니다.
ENTRYPOINT ["java", "-jar", "/app/app.jar"]