#!/bin/bash
# proxy-agent-setup-hvr.sh
# Fivetran Proxy Agent (HVR) automated installation on Linux

set -e

# Variables from Terraform
SECRET_ARN="${secret_arn}"
AWS_REGION="${aws_region}"
HVR_VERSION="${hvr_version}"
HVR_DOWNLOAD_URL="${hvr_download_url}"

echo "========================================="
echo "Fivetran Proxy Agent (HVR) Setup"
echo "========================================="

# ============================================================================
# System Updates
# ============================================================================
echo "==> Updating system packages..."
dnf update -y

# ============================================================================
# Install AWS CLI and jq
# ============================================================================
echo "==> Installing AWS CLI and jq..."
dnf install -y aws-cli jq wget

# ============================================================================
# Install CloudWatch Agent
# ============================================================================
echo "==> Installing CloudWatch agent..."
curl -sLO https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
rpm -U amazon-cloudwatch-agent.rpm
rm -f amazon-cloudwatch-agent.rpm

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CWEOF'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/home/fivetran/hvr_config/proxy/log/agent-out.log",
            "log_group_name": "/aws/fivetran-proxy-agent",
            "log_stream_name": "{instance_id}",
            "timezone": "UTC"
          }
        ]
      }
    }
  }
}
CWEOF

systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# ============================================================================
# Create fivetran user
# ============================================================================
echo "==> Creating fivetran user..."
useradd -m -s /bin/bash fivetran

# ============================================================================
# Setup HVR directories and environment
# ============================================================================
echo "==> Setting up HVR environment..."

# Create directories
sudo -u fivetran bash <<'EOF'
umask 022
mkdir -p /home/fivetran/hvr_home
mkdir -p /home/fivetran/hvr_config/proxy
mkdir -p /home/fivetran/hvr_tmp

# Set environment variables in .profile
cat >> /home/fivetran/.profile <<'PROFILE'
export HVR_HOME=/home/fivetran/hvr_home
export HVR_CONFIG=/home/fivetran/hvr_config
export HVR_TMP=/home/fivetran/hvr_tmp
export PATH=$PATH:$HVR_HOME/bin
PROFILE
EOF

# ============================================================================
# Download and Extract HVR Agent
# ============================================================================
echo "==> Downloading Fivetran High-Volume Agent..."

# Download to /tmp
cd /tmp
wget -q "$HVR_DOWNLOAD_URL" -O hvr-agent.tar.gz

# Extract to HVR_HOME
echo "==> Extracting HVR Agent..."
sudo -u fivetran tar xzf /tmp/hvr-agent.tar.gz -C /home/fivetran/hvr_home

# Cleanup download
rm -f /tmp/hvr-agent.tar.gz

# ============================================================================
# Retrieve Proxy Agent Configuration from Secrets Manager
# ============================================================================
echo "==> Retrieving Proxy Agent configuration from Secrets Manager..."

# Get config from Secrets Manager
CONFIG_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "$SECRET_ARN" \
  --region "$AWS_REGION" \
  --query 'SecretString' \
  --output text)

# Verify config was retrieved
if [ -z "$CONFIG_JSON" ]; then
  echo "ERROR: Failed to retrieve configuration from Secrets Manager!"
  exit 1
fi

# Write to proxyagent.conf
echo "$CONFIG_JSON" > /home/fivetran/hvr_config/proxy/proxyagent.conf
chown fivetran:fivetran /home/fivetran/hvr_config/proxy/proxyagent.conf
chmod 600 /home/fivetran/hvr_config/proxy/proxyagent.conf

echo "==> Configuration retrieved successfully"

# ============================================================================
# Create Systemd Service
# ============================================================================
echo "==> Creating systemd service for Fivetran Proxy Agent..."

cat > /etc/systemd/system/fivetran_proxy.service <<'SERVICEEOF'
[Unit]
Description=Fivetran Proxy Agent

[Service]
Type=simple
User=root

ExecStart=/home/fivetran/hvr_home/jre/bin/java \
  -XX:+HeapDumpOnOutOfMemoryError \
  -XX:HeapDumpPath=/home/fivetran/hvr_config/proxy/ \
  -jar /home/fivetran/hvr_home/proxy/proxyagent.jar \
  /home/fivetran/hvr_config/proxy/proxyagent.conf

# Restart this service after a crash
Restart=always

# The number of seconds to wait before attempting a restart
RestartSec=5s

[Install]
WantedBy=multi-user.target
SERVICEEOF

# ============================================================================
# Set permissions for root access
# ============================================================================
echo "==> Setting proper permissions..."
chmod -R 755 /home/fivetran/hvr_home
chmod -R 755 /home/fivetran/hvr_config
chmod -R 755 /home/fivetran/hvr_tmp

# ============================================================================
# Start Fivetran Proxy Agent
# ============================================================================
echo "==> Starting Fivetran Proxy Agent service..."
systemctl daemon-reload
systemctl enable fivetran_proxy.service
systemctl start fivetran_proxy.service

sleep 5

systemctl status fivetran_proxy --no-pager || true

echo ""
echo "========================================="
echo "✓ Fivetran Proxy Agent Setup Complete!"
echo "========================================="
echo ""
echo "Config retrieved from: $SECRET_ARN"
echo "HVR Version: $HVR_VERSION"
echo "Agent should be connecting to Fivetran..."
echo ""
