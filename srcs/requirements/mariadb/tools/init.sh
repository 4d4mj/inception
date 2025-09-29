#!/bin/bash

# Read secrets from Docker secrets
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
MYSQL_PASSWORD=$(cat /run/secrets/db_password)

# Start MariaDB in the background
mysqld_safe --user=mysql --datadir=/var/lib/mysql &

# Wait for MariaDB to be ready
until mysqladmin ping -h localhost --silent; do
    echo "Waiting for MariaDB to be ready..."
    sleep 2
done

# Check if database has been initialized by looking for our marker file
INIT_MARKER=/var/lib/mysql/.inception_initialized

if [ ! -f "$INIT_MARKER" ]; then
    echo "First time setup - configuring MariaDB..."
    # First run - set root password and create database
    mysql -u root <<EOF
SET @root_pass = PASSWORD('$MYSQL_ROOT_PASSWORD');
ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD(@root_pass);
ALTER USER IF EXISTS 'root'@'127.0.0.1' IDENTIFIED VIA mysql_native_password USING PASSWORD(@root_pass);
ALTER USER IF EXISTS 'root'@'::1' IDENTIFIED VIA mysql_native_password USING PASSWORD(@root_pass);
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';
FLUSH PRIVILEGES;
EOF

    touch "$INIT_MARKER"
    chown mysql:mysql "$INIT_MARKER"
else
    echo "MariaDB already configured - checking database..."
    # Database already configured, just ensure our database exists
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" <<EOF
CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';
FLUSH PRIVILEGES;
EOF
fi

# Stop the background process and start normally
mysqladmin -u root -p"$MYSQL_ROOT_PASSWORD" shutdown

# Start MariaDB normally (foreground)
exec "$@"
