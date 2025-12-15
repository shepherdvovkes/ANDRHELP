#!/bin/bash
# Final fix for nginx WebSocket configuration
# This script properly updates the andrhelp-ws location block

CONFIG_FILE="/etc/nginx/sites-available/mail.s0me.uk"
BACKUP_FILE="${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"

# Backup
sudo cp "$CONFIG_FILE" "$BACKUP_FILE"

# Restore from the earliest backup if current is corrupted
EARLIEST_BACKUP=$(ls -t /etc/nginx/sites-available/mail.s0me.uk.backup.* 2>/dev/null | tail -1)
if [ -n "$EARLIEST_BACKUP" ]; then
    echo "Restoring from backup: $EARLIEST_BACKUP"
    sudo cp "$EARLIEST_BACKUP" "$CONFIG_FILE"
fi

# Update port from 4000 to 3100
sudo sed -i 's|proxy_pass http://127.0.0.1:4000;|proxy_pass http://localhost:3100;|g' "$CONFIG_FILE"

# Update timeouts
sudo sed -i 's|proxy_read_timeout 300s;|proxy_read_timeout 86400;|g' "$CONFIG_FILE"
sudo sed -i 's|proxy_send_timeout 300s;|proxy_send_timeout 86400;|g' "$CONFIG_FILE"

# Add location block without trailing slash BEFORE the one with trailing slash
# Find the line with "location /andrhelp-ws/" and insert before it
sudo sed -i '/location \/andrhelp-ws\/ {/i\
    location /andrhelp-ws {\
        proxy_pass http://localhost:3100;\
        proxy_http_version 1.1;\
        proxy_set_header Upgrade $http_upgrade;\
        proxy_set_header Connection "upgrade";\
        proxy_set_header Host $host;\
        proxy_set_header X-Real-IP $remote_addr;\
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\
        proxy_set_header X-Forwarded-Proto $scheme;\
        proxy_cache_bypass $http_upgrade;\
        proxy_read_timeout 86400;\
        proxy_send_timeout 86400;\
        proxy_buffering off;\
    }\
' "$CONFIG_FILE"

# Test and reload
if sudo nginx -t; then
    echo "✅ Configuration is valid. Reloading nginx..."
    sudo systemctl reload nginx
    echo "✅ Nginx reloaded successfully!"
    echo "WebSocket endpoint: wss://mail.s0me.uk/andrhelp-ws"
else
    echo "❌ ERROR: Nginx configuration test failed!"
    echo "Restoring backup..."
    sudo cp "$BACKUP_FILE" "$CONFIG_FILE"
    exit 1
fi

