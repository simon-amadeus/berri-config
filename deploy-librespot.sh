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
    # Create dedicated librespot user if it doesn'\''t exist
    if ! id -u librespot >/dev/null 2>&1; then
        echo "Creating librespot system user..."
        sudo useradd --system --no-create-home --shell /bin/false \
                     --groups audio,avahi --comment "Librespot service user" librespot
    else
        echo "Librespot user already exists"
        # Ensure user is in correct groups
        sudo usermod -a -G audio,avahi librespot
    fi
    
    sudo cp /tmp/librespot.service /usr/lib/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable librespot.service
    sudo systemctl restart librespot.service
    
    # Basic firewall setup
    if command -v ufw >/dev/null; then
        sudo ufw allow 22/tcp comment "ssh" >/dev/null 2>&1 || true
        sudo ufw allow 5353/udp comment "mDNS" >/dev/null 2>&1 || true  
        sudo ufw allow 36593/tcp comment "librespot" >/dev/null 2>&1 || true
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
