# Multi-stage build
FROM maven:3.9-openjdk-21-slim AS builder

WORKDIR /app

# Copy parent POM and shared module first for better layer caching
COPY ../pom.xml ./pom.xml
COPY ../shared-module ./shared-module

# Copy gateway service
COPY pom.xml ./gateway-service/pom.xml
COPY src ./gateway-service/src

# Build the application
RUN mvn clean package -DskipTests -f gateway-service/pom.xml

# Runtime stage
FROM openjdk:21-jre-slim

WORKDIR /app

# Copy the JAR from builder stage
COPY --from=builder /app/gateway-service/target/gateway-service-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"] 