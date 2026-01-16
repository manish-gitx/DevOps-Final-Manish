# Multi-stage build to keep the runtime image small and secure
FROM maven:3.9-eclipse-temurin-17 AS builder
WORKDIR /app
COPY pom.xml .
COPY checkstyle.xml .
COPY src ./src
RUN mvn -B -DskipTests package

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# Apply all security patches to fix OS-level CVEs
RUN apk update && apk upgrade --no-cache && rm -rf /var/cache/apk/*

RUN addgroup -S app && adduser -S app -G app
COPY --from=builder /app/target/devops-ci-api.jar /app/app.jar
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget -qO- http://localhost:8080/users || exit 1
USER app
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
