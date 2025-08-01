#!/bin/bash

echo "=== K3s Setup Script for Payment System ==="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
echo "Checking prerequisites..."

if ! command_exists docker; then
    echo "❌ Docker not found. Please install Docker first."
    exit 1
fi

if ! command_exists curl; then
    echo "❌ curl not found. Please install curl first."
    exit 1
fi

echo "✅ Prerequisites met"

# Install K3s if not already installed
if ! command_exists k3s; then
    echo "Installing K3s..."
    curl -sfL https://get.k3s.io | sh -
    
    # Add current user to k3s group (optional, for easier kubectl access)
    sudo chmod 644 /etc/rancher/k3s/k3s.yaml
    
    echo "✅ K3s installed successfully"
else
    echo "✅ K3s already installed"
fi

# Set up kubectl alias for k3s
echo "Setting up kubectl..."
sudo cp /usr/local/bin/k3s /usr/local/bin/kubectl
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# Wait for K3s to be ready
echo "Waiting for K3s to be ready..."
sleep 10

# Check K3s status
if sudo k3s kubectl get nodes >/dev/null 2>&1; then
    echo "✅ K3s is running"
    sudo k3s kubectl get nodes
else
    echo "❌ K3s is not ready. Please check the installation."
    exit 1
fi

# Start local Docker registry
echo "Setting up local Docker registry..."
if docker ps | grep -q "registry:2"; then
    echo "✅ Registry already running"
else
    docker run -d -p 5000:5000 --name registry --restart=always registry:2
    echo "✅ Local registry started on port 5000"
fi

# Configure K3s to use insecure registry
echo "Configuring K3s for local registry..."
sudo mkdir -p /etc/rancher/k3s
sudo tee /etc/rancher/k3s/registries.yaml > /dev/null <<EOF
mirrors:
  "localhost:5000":
    endpoint:
      - "http://localhost:5000"
configs:
  "localhost:5000":
    tls:
      insecure_skip_verify: true
EOF

# Restart K3s to apply registry configuration
echo "Restarting K3s to apply registry configuration..."
sudo systemctl restart k3s

# Wait for restart
sleep 15

echo ""
echo "🎉 K3s setup completed successfully!"
echo ""
echo "Next steps:"
echo "1. cd k8s"
echo "2. ./deploy.sh"
echo ""
echo "Useful commands:"
echo "- Check cluster: sudo k3s kubectl get nodes"
echo "- Check pods: sudo k3s kubectl get pods -n payment-system"
echo "- Check services: sudo k3s kubectl get services -n payment-system"
echo "- Registry status: docker ps | grep registry"