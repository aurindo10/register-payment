#!/bin/bash

echo "Building Payment System Docker Images with Multi-stage Build..."

echo "Building Gateway Service image (includes Maven build)..."
cd gateway-service
docker build -t optica/gateway-service:latest .
cd ..

echo "Building Consumer Service image (includes Maven build)..."
cd consumer-service
docker build -t optica/consumer-service:latest .
cd ..

echo "Docker images built successfully!"
echo "Images:"
echo "- optica/gateway-service:latest"
echo "- optica/consumer-service:latest"
echo ""
echo "Note: Java/Maven build happens inside Docker containers" 