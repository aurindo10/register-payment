#!/bin/bash

echo "=== K3s Setup Script for Payment System ==="

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Update system packages
echo "Updating system packages..."
sudo apt update

# Install Java 21
echo "Installing Java 21..."
if ! command_exists java; then
    sudo apt install -y openjdk-21-jdk
    echo "✅ Java 21 installed"
else
    JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d'.' -f1)
    if [ "$JAVA_VERSION" != "21" ]; then
        echo "⚠️  Java version $JAVA_VERSION found, installing Java 21..."
        sudo apt install -y openjdk-21-jdk
        sudo update-alternatives --config java
    fi
    echo "✅ Java 21 available"
fi

# Set JAVA_HOME
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
echo "export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64" >> ~/.bashrc

# Install Maven
echo "Installing Maven..."
if ! command_exists mvn; then
    sudo apt install -y maven
    echo "✅ Maven installed"
else
    echo "✅ Maven already installed"
fi

# Install Docker if not present
echo "Installing Docker..."
if ! command_exists docker; then
    # Install Docker
    sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    echo "✅ Docker installed (logout/login required for docker group)"
else
    echo "✅ Docker already installed"
fi

# Install curl if not present
if ! command_exists curl; then
    sudo apt install -y curl
    echo "✅ curl installed"
fi

# Verify versions
echo ""
echo "=== Installed Versions ==="
java -version
mvn -version
docker --version

echo "✅ All prerequisites met"

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