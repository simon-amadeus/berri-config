#!/bin/bash
# Minimal librespot deployment to Raspberry Pi

set -e
REMOTE_HOST="knowone@berri.local"
LIBRESPOT_PORT=36593

echo "Deploying librespot to $REMOTE_HOST..."

# Copy service file
scp librespot.service "$REMOTE_HOST:/tmp/"

# Deploy and start
ssh "$REMOTE_HOST" '
    sudo cp /tmp/librespot.service /usr/lib/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable librespot.service
    sudo systemctl restart librespot.service
    
    # Basic firewall setup
    if command -v ufw >/dev/null; then
        sudo ufw allow 22/tcp >/dev/null 2>&1 || true
        sudo ufw allow 5353/udp >/dev/null 2>&1 || true  
        sudo ufw allow 36593/tcp >/dev/null 2>&1 || true
    fi
    
    # Status check
    if systemctl is-active --quiet librespot.service; then
        echo "✓ Librespot deployed successfully"
    else
        echo "✗ Service failed to start"
        systemctl status librespot.service --no-pager
        exit 1
    fi
'
