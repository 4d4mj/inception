# Step 1: Determine your base image
FROM debian:bookworm

# Step 2: Install application dependencies
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends mariadb-server mariadb-client \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /run/mysqld \
    && chown -R mysql:mysql /run/mysqld /var/lib/mysql

# Step 3: Copy in any relevant configuration files
COPY ./tools/init.sh /usr/local/bin/init.sh
RUN chmod +x /usr/local/bin/init.sh

# Configure MariaDB to accept connections from any host
RUN sed -i 's/bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf

# Step 4: Configure the final image
EXPOSE 3306
ENTRYPOINT ["/usr/local/bin/init.sh"]
CMD ["mysqld_safe"]
