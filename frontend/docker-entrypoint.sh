#!/bin/sh
set -e

# Set default backend URL if not provided
export BACKEND_URL=${BACKEND_URL:-"http://localhost:8000"}

# Log the backend URL for debugging
echo "==================================="
echo "Docker Entrypoint - Nginx Configuration"
echo "==================================="
echo "BACKEND_URL: $BACKEND_URL"
echo "==================================="

# Substitute environment variables in nginx config template
envsubst '${BACKEND_URL}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Show the generated config for debugging
echo "Generated nginx config (proxy sections):"
grep -A 5 "location /chatkit" /etc/nginx/nginx.conf || echo "No /chatkit location found"
echo "==================================="

# Test nginx configuration
nginx -t

# Execute the main command
exec "$@"
