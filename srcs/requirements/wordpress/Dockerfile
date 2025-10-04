# Use Debian Bookworm as base image
FROM debian:bookworm

# Update packages and install wget for downloading files
RUN apt-get update && \
    apt-get install -y wget

# Create directory for web files
RUN mkdir /var/www
# Install PHP, PHP-FPM, and PHP MySQL extension
RUN apt-get install -y php php-fpm php-mysql

# Install MariaDB client and curl
RUN apt-get install -y mariadb-client && apt install curl -y

# Copy start script and make it executable
COPY ./tools/start.sh /
RUN chmod +x start.sh

# Set start script as container command
CMD ["/start.sh"]