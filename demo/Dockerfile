# 1. 베이스 이미지 선택 (Java 11 사용)
FROM openjdk:21

# 3. JAR 파일이 위치할 컨테이너 내 디렉토리 생성
WORKDIR /app

# 4. Gradle 빌드로 생성된 JAR 파일을 컨테이너로 복사
# build/libs/ 디렉토리 아래에 있는 .jar 파일을 app.jar 라는 이름으로 복사합니다.
COPY build/libs/*.jar app.jar

# 5. 컨테이너가 외부에 노출할 포트 설정 (애플리케이션 포트와 일치)
EXPOSE 8080

# 6. 컨테이너가 시작될 때 실행할 명령어
ENTRYPOINT ["java", "-jar", "/app/app.jar"]