#!/bin/bash

# AWS VM Setup Script for Payment System
# Run this script on a fresh Ubuntu 22.04 LTS instance

set -e

echo "🚀 Setting up Payment System on AWS VM..."

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Docker
echo "🐳 Installing Docker..."
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Install Docker Compose
echo "📦 Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Add user to docker group
sudo usermod -aG docker $USER

# Install Java 21 (for building locally if needed)
echo "☕ Installing Java 21..."
sudo apt install -y openjdk-21-jdk

# Install Maven
echo "📋 Installing Maven..."
sudo apt install -y maven

# Install Nginx (as backup/alternative)
echo "🌐 Installing Nginx..."
sudo apt install -y nginx

# Install monitoring tools
echo "📊 Installing monitoring tools..."
sudo apt install -y htop iotop netstat-nat curl wget git tree

# Create application directory
echo "📁 Creating application directory..."
sudo mkdir -p /opt/payment-system
sudo chown $USER:$USER /opt/payment-system

# Configure firewall
echo "🔥 Configuring firewall..."
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 8080  # Gateway Service
sudo ufw allow 8081  # Consumer Service (optional, for direct access)
sudo ufw allow 15672 # RabbitMQ Management (optional)
sudo ufw --force enable

# Create systemd service for docker-compose
echo "⚙️  Creating systemd service..."
sudo tee /etc/systemd/system/payment-system.service > /dev/null <<EOF
[Unit]
Description=Payment System
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/payment-system
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable payment-system

# Create backup script
echo "💾 Creating backup script..."
sudo tee /usr/local/bin/backup-payment-system.sh > /dev/null <<'EOF'
#!/bin/bash
BACKUP_DIR="/opt/backups/payment-system"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup PostgreSQL
docker exec payment-postgres pg_dump -U postgres optica-db > $BACKUP_DIR/postgres_backup_$DATE.sql

# Backup Docker volumes
docker run --rm -v payment-system_postgres_data:/data -v $BACKUP_DIR:/backup ubuntu tar czf /backup/postgres_data_$DATE.tar.gz -C /data .
docker run --rm -v payment-system_rabbitmq_data:/data -v $BACKUP_DIR:/backup ubuntu tar czf /backup/rabbitmq_data_$DATE.tar.gz -C /data .

# Keep only last 7 days of backups
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete

echo "Backup completed: $BACKUP_DIR"
EOF

sudo chmod +x /usr/local/bin/backup-payment-system.sh

# Setup cron for daily backups
echo "⏰ Setting up daily backups..."
echo "0 2 * * * /usr/local/bin/backup-payment-system.sh" | sudo crontab -

# Create log rotation
echo "📝 Setting up log rotation..."
sudo tee /etc/logrotate.d/payment-system > /dev/null <<EOF
/opt/payment-system/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
    postrotate
        docker-compose -f /opt/payment-system/docker-compose.yml restart nginx
    endscript
}
EOF

echo "✅ VM setup completed!"
echo ""
echo "Next steps:"
echo "1. Logout and login again (for docker group to take effect)"
echo "2. Clone your project to /opt/payment-system"
echo "3. Run the deploy script"
echo ""
echo "Useful commands:"
echo "- sudo systemctl start payment-system  # Start services"
echo "- sudo systemctl stop payment-system   # Stop services"
echo "- sudo systemctl status payment-system # Check status"
echo "- /usr/local/bin/backup-payment-system.sh # Manual backup" 