#!/bin/bash

# Create SSL directory
mkdir -p /etc/nginx/ssl

# Generate SSL certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/nginx.key \
    -out /etc/nginx/ssl/nginx.crt \
    -subj "/C=US/ST=CA/L=SF/O=42/CN=${DOMAIN_NAME}"

# Replace domain placeholder in nginx config
sed -i "s/DOMAIN_NAME_PLACEHOLDER/${DOMAIN_NAME}/g" /etc/nginx/nginx.conf

# Start NGINX
echo "Starting NGINX..."
exec nginx -g "daemon off;"
