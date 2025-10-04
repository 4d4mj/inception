# Use Debian Bookworm as base image
FROM debian:bookworm

# Install MariaDB server and client, clean up apt cache and existing MySQL data
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        mariadb-server \
        mariadb-client \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /var/lib/mysql/*

# Create runtime directories and set ownership to mysql user
RUN mkdir -p /run/mysqld /var/lib/mysql \
    && chown -R mysql:mysql /run/mysqld /var/lib/mysql \
    && chmod 755 /run/mysqld

# Configure MariaDB to listen on all interfaces and add performance optimizations
RUN sed -i 's/bind-address\s*=.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf \
    && echo "[mysqld]\nskip-host-cache\nskip-name-resolve" > /etc/mysql/mariadb.conf.d/99-docker.cnf

# Copy init script and make it executable
COPY ./tools/init.sh /usr/local/bin/init.sh
RUN chmod +x /usr/local/bin/init.sh

# Expose port 3306 for database connections
EXPOSE 3306
# Switch to mysql user for security
USER mysql
# Set init script as container entrypoint
ENTRYPOINT ["/usr/local/bin/init.sh"]