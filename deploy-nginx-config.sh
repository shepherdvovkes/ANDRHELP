#!/bin/bash
# Deploy nginx configuration from GitHub repository
# Run this on mail.s0me.uk server

REPO_URL="https://github.com/shepherdvovkes/ANDRHELP.git"
TEMP_DIR=$(mktemp -d)
NGINX_CONFIG="/etc/nginx/sites-available/mail.s0me.uk"
BACKUP_FILE="${NGINX_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"

echo "Cloning repository..."
cd "$TEMP_DIR"
git clone "$REPO_URL" andrhelp-repo

echo "Backing up current nginx config..."
sudo cp "$NGINX_CONFIG" "$BACKUP_FILE"

echo "Applying nginx WebSocket configuration..."
# Remove old andrhelp-ws location blocks if they exist
sudo sed -i '/location \/andrhelp-ws/,/^[[:space:]]*}/d' "$NGINX_CONFIG"

# Insert the new configuration before the last location block or before the closing brace
# Find a good insertion point (before /court-update/ or before the final location /)
if grep -q "location /court-update/" "$NGINX_CONFIG"; then
    sudo sed -i '/location \/court-update\//i\
'"$(cat andrhelp-repo/andrhelp-ws-location.conf)"'
' "$NGINX_CONFIG"
else
    # Insert before the final location / block
    sudo sed -i '/^[[:space:]]*location \/ {$/i\
'"$(cat andrhelp-repo/andrhelp-ws-location.conf)"'
' "$NGINX_CONFIG"
fi

echo "Testing nginx configuration..."
if sudo nginx -t; then
    echo "✅ Configuration is valid. Reloading nginx..."
    sudo systemctl reload nginx
    echo "✅ Nginx reloaded successfully!"
    echo "WebSocket endpoint should now be available at: wss://mail.s0me.uk/andrhelp-ws"
else
    echo "❌ ERROR: Nginx configuration test failed!"
    echo "Restoring backup..."
    sudo cp "$BACKUP_FILE" "$NGINX_CONFIG"
    exit 1
fi

# Cleanup
rm -rf "$TEMP_DIR"
echo "✅ Deployment complete!"

