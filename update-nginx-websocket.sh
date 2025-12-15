#!/bin/bash
# Script to update nginx configuration for ANDRHELP WebSocket support
# Run this on mail.s0me.uk server

NGINX_CONFIG="/etc/nginx/sites-available/mail.s0me.uk"
BACKUP_CONFIG="${NGINX_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"

echo "Backing up current nginx config to ${BACKUP_CONFIG}..."
sudo cp "${NGINX_CONFIG}" "${BACKUP_CONFIG}"

echo "Checking if WebSocket location already exists..."
if sudo grep -q "location /andrhelp-ws" "${NGINX_CONFIG}"; then
    echo "WebSocket location found. Updating..."
    # Remove existing andrhelp-ws location block
    sudo sed -i '/location \/andrhelp-ws/,/^[[:space:]]*}/d' "${NGINX_CONFIG}"
fi

echo "Adding WebSocket configuration..."
# Find the server block and add the location block before the closing brace
sudo sed -i '/server {/,/^[[:space:]]*}/ {
    /^[[:space:]]*}/ i\
    # ANDRHELP WebSocket proxy\
    location /andrhelp-ws {\
        proxy_http_version 1.1;\
        proxy_set_header Upgrade $http_upgrade;\
        proxy_set_header Connection "upgrade";\
        proxy_set_header Host $host;\
        proxy_set_header X-Real-IP $remote_addr;\
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;\
        proxy_set_header X-Forwarded-Proto $scheme;\
        proxy_read_timeout 86400;\
        proxy_send_timeout 86400;\
        proxy_buffering off;\
        proxy_pass http://localhost:3100;\
    }
}' "${NGINX_CONFIG}"

echo "Testing nginx configuration..."
if sudo nginx -t; then
    echo "Configuration is valid. Reloading nginx..."
    sudo systemctl reload nginx
    echo "Nginx reloaded successfully!"
    echo "WebSocket endpoint should now be available at: wss://mail.s0me.uk/andrhelp-ws"
else
    echo "ERROR: Nginx configuration test failed!"
    echo "Restoring backup..."
    sudo cp "${BACKUP_CONFIG}" "${NGINX_CONFIG}"
    exit 1
fi

