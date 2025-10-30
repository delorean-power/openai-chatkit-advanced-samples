#!/bin/sh
set -e

# Set default backend URL if not provided
export BACKEND_URL=${BACKEND_URL:-"http://localhost:8000"}

# Substitute environment variables in nginx config template
envsubst '${BACKEND_URL}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Test nginx configuration
nginx -t

# Execute the main command
exec "$@"
