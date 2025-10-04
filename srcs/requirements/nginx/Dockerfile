# Use Debian Bookworm as base image
FROM debian:bookworm

# Update packages, install Nginx and OpenSSL, clean up apt cache
RUN apt-get update && \
    apt-get install -y nginx openssl && \
    rm -rf /var/lib/apt/lists/*

# Copy custom Nginx configuration
COPY conf/default.conf /etc/nginx/sites-available/default

# Generate self-signed SSL certificate (valid 365 days) with 2048-bit RSA key
RUN openssl req -x509 -nodes -days 365 \
    -subj "/C=LB/ST=Lebanon/L=Beirut/O=42/OU=Student/CN=ajabado.42.fr" \
    -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt

# Expose port 443 for HTTPS
EXPOSE 443
# Start Nginx in foreground mode
CMD ["nginx", "-g", "daemon off;"]
