# Stage 1: Build the application using Maven and Java 21
FROM maven:3.9.6-eclipse-temurin-21 AS builder

WORKDIR /app

# Copy Maven files and source code
COPY pom.xml .
COPY src ./src

# Build the application without running tests
RUN mvn clean package -DskipTests

# Stage 2: Run the application with a slim Java 21 runtime
FROM eclipse-temurin:21-jdk-alpine

WORKDIR /app

# Copy built JAR from the builder stage
COPY --from=builder /app/target/*.jar app.jar

# Expose the Spring Boot port
EXPOSE 8080

# Environment variables (just for reference/documentation)
ENV AWS_ACCESS_KEY=""
ENV AWS_SECRET_KEY=""
ENV S3_BUCKET_REGION=""
ENV S3_BUCKET_NAME=""
ENV DB_HOST=""
ENV DB_PORT=""
ENV DB_NAME=""
ENV DB_USERNAME=""
ENV DB_PASSWORD=""

# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]

