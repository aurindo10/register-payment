#!/bin/bash

echo "Deploying Payment System to Kubernetes..."

echo "Creating namespace..."
kubectl apply -f namespace.yaml

echo "Creating ConfigMaps and Secrets..."
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml

echo "Deploying PostgreSQL..."
kubectl apply -f postgres.yaml

echo "Deploying RabbitMQ..."
kubectl apply -f rabbitmq.yaml

echo "Waiting for PostgreSQL and RabbitMQ to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n payment-system --timeout=300s
kubectl wait --for=condition=ready pod -l app=rabbitmq -n payment-system --timeout=300s

echo "Deploying Gateway Service..."
kubectl apply -f gateway-service.yaml

echo "Deploying Consumer Service..."
kubectl apply -f consumer-service.yaml

echo "Creating Ingress..."
kubectl apply -f ingress.yaml

echo "Waiting for services to be ready..."
kubectl wait --for=condition=ready pod -l app=gateway-service -n payment-system --timeout=300s
kubectl wait --for=condition=ready pod -l app=consumer-service -n payment-system --timeout=300s

echo "Deployment completed!"
echo ""
echo "Services:"
echo "Gateway Service: http://payment-gateway.local"
echo "RabbitMQ Management: http://rabbitmq-management.local"
echo ""
echo "To check status:"
echo "kubectl get pods -n payment-system"
echo "kubectl get services -n payment-system" 