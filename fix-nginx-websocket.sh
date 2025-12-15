#!/bin/bash
# Fix nginx WebSocket configuration for ANDRHELP

CONFIG_FILE="/etc/nginx/sites-available/mail.s0me.uk"
BACKUP_FILE="${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"

# Backup
sudo cp "$CONFIG_FILE" "$BACKUP_FILE"

# Create temporary file with the new location blocks
TEMP_FILE=$(mktemp)
cat > "$TEMP_FILE" << 'EOF'
    # ANDRHELP WebSocket proxy
    location /andrhelp-ws {
        proxy_pass http://localhost:3100;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
        proxy_buffering off;
    }

    # ANDRHELP WebSocket proxy (with trailing slash)
    location /andrhelp-ws/ {
        proxy_pass http://localhost:3100/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 86400;
        proxy_send_timeout 86400;
        proxy_buffering off;
    }
EOF

# Replace lines 122-141 with the new configuration
sudo sed -i '122,141d' "$CONFIG_FILE"
sudo sed -i "121r $TEMP_FILE" "$CONFIG_FILE"

# Clean up temp file
rm "$TEMP_FILE"

# Test configuration
if sudo nginx -t; then
    echo "Configuration is valid. Reloading nginx..."
    sudo systemctl reload nginx
    echo "Nginx reloaded successfully!"
    echo "WebSocket endpoint should now be available at: wss://mail.s0me.uk/andrhelp-ws"
else
    echo "ERROR: Nginx configuration test failed!"
    echo "Restoring backup..."
    sudo cp "$BACKUP_FILE" "$CONFIG_FILE"
    exit 1
fi

