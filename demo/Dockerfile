# 사용할 Java 버전에 맞는 베이스 이미지를 선택합니다.
FROM openjdk:21

# 빌드된 JAR 파일이 위치할 경로를 지정합니다.
ARG JAR_FILE=build/libs/*.jar

# 빌드된 JAR 파일을 컨테이너 내부로 복사합니다.
COPY ${JAR_FILE} app.jar

# 애플리케이션 실행 명령어입니다.
ENTRYPOINT ["java","-jar","/app.jar"]