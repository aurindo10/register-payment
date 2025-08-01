# Multi-stage build
FROM maven:3.9-openjdk-21-slim AS builder

WORKDIR /app

# Copy parent POM and shared module first for better layer caching
COPY ../pom.xml ./pom.xml
COPY ../shared-module ./shared-module

# Copy consumer service
COPY pom.xml ./consumer-service/pom.xml
COPY src ./consumer-service/src

# Build the application
RUN mvn clean package -DskipTests -f consumer-service/pom.xml

# Runtime stage
FROM openjdk:21-jre-slim

WORKDIR /app

# Copy the JAR from builder stage
COPY --from=builder /app/consumer-service/target/consumer-service-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8081

ENTRYPOINT ["java", "-jar", "app.jar"] 