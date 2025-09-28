# Stable, lightweight base
FROM debian:bookworm

# Install application dependencies (Web server + SSL tools)
RUN apt-get update && \
    apt-get install -y nginx openssl && \
    rm -rf /var/lib/apt/lists/*

# Copy in any relevant configuration files (Custom config)
COPY conf/default.conf /etc/nginx/sites-available/default

# Configure the final image (SSL setup, expose port, start server)
RUN openssl req -x509 -nodes -days 365 \
    -subj "/C=LB/ST=Lebanon/L=Beirut/O=42/OU=Student/CN=ajabado.42.fr" \
    -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt

EXPOSE 443
CMD ["nginx", "-g", "daemon off;"]
