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
    echo "Reloading nginx..."
    sudo systemctl reload nginx
    echo "✅ Nginx reloaded successfully!"
    echo ""
    echo "awe.s0me.uk is now configured (HTTP only for now)"
    echo "To enable HTTPS:"
    echo "1. Get SSL certificate: sudo certbot certonly --nginx -d awe.s0me.uk"
    echo "2. Uncomment the HTTPS server block in $NGINX_AVAILABLE"
    echo "3. Uncomment the HTTP redirect"
    echo "4. Run: sudo nginx -t && sudo systemctl reload nginx"
else
    echo "❌ ERROR: Nginx configuration test failed!"
    exit 1
fi

