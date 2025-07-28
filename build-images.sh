#!/bin/bash

echo "Building Payment System Docker Images..."

echo "Building parent project..."
mvn clean install -DskipTests

echo "Building Gateway Service image..."
cd gateway-service
mvn clean package -DskipTests
docker build -t optica/gateway-service:latest .
cd ..

echo "Building Consumer Service image..."
cd consumer-service
mvn clean package -DskipTests
docker build -t optica/consumer-service:latest .
cd ..

echo "Docker images built successfully!"
echo "Images:"
echo "- optica/gateway-service:latest"
echo "- optica/consumer-service:latest" 