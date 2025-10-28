#!/bin/bash
# Minimal librespot deployment to Raspberry Pi

set -e
REMOTE_HOST="knowone@berri.local"
LIBRESPOT_PORT=36593

echo "Deploying librespot to $REMOTE_HOST..."

# Copy service file
echo "Copying service file..."
scp librespot.service "$REMOTE_HOST:/tmp/"

# Deploy and start
ssh "$REMOTE_HOST" '
    # Install librespot if not already present
    if ! command -v librespot >/dev/null 2>&1; then
        echo "Installing librespot..."
        cargo install librespot --no-default-features --features "native-tls alsa-backend with-avahi"
        sudo cp ~/.cargo/bin/librespot /usr/bin/librespot
    else
        echo "Librespot already installed, skipping installation"
    fi
    
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
    echo "Configuring systemd service..."
    sudo systemctl daemon-reload
    sudo systemctl enable librespot.service
    sudo systemctl restart librespot.service
    
    # Basic firewall setup
    if command -v ufw >/dev/null; then
        echo "Configuring firewall..."
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
