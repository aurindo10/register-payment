#!/bin/bash

# User data script for Payment System EC2 instance
set -e

# Log everything
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "Starting Payment System setup..."

# Update system
apt update && apt upgrade -y

# Install basic dependencies
apt install -y curl wget git unzip

# Download and run setup script
cd /opt
git clone ${git_repo} payment-system
cd payment-system

# Make scripts executable
chmod +x aws-vm-setup.sh deploy-vm.sh

# Run setup (as ubuntu user)
sudo -u ubuntu ./aws-vm-setup.sh

# Change ownership to ubuntu user
chown -R ubuntu:ubuntu /opt/payment-system

echo "Setup completed. Ready for deployment." 