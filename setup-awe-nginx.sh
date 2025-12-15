#!/bin/bash
# Setup nginx configuration for awe.s0me.uk
# Run this on the server

CONFIG_SOURCE="nginx-awe.s0me.uk.conf"
NGINX_AVAILABLE="/etc/nginx/sites-available/awe.s0me.uk"
NGINX_ENABLED="/etc/nginx/sites-enabled/awe.s0me.uk"

if [ ! -f "$CONFIG_SOURCE" ]; then
    echo "❌ Error: $CONFIG_SOURCE not found!"
    echo "Make sure you're in the ANDRHELP repository directory"
    exit 1
fi

echo "Copying nginx configuration..."
sudo cp "$CONFIG_SOURCE" "$NGINX_AVAILABLE"

echo "Creating symlink..."
sudo ln -sf "$NGINX_AVAILABLE" "$NGINX_ENABLED"

echo "Testing nginx configuration..."
if sudo nginx -t; then
    echo "✅ Configuration is valid!"
    echo ""
    echo "Next steps:"
    echo "1. Update SSL certificate paths in $NGINX_AVAILABLE if needed"
    echo "2. Run: sudo systemctl reload nginx"
    echo "3. Verify DNS points awe.s0me.uk to this server"
else
    echo "❌ ERROR: Nginx configuration test failed!"
    exit 1
fi

