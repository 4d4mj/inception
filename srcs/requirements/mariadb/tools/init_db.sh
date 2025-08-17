#!/bin/bash

# Initialize MySQL data directory if it doesn't exist
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing MariaDB data directory..."
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql --skip-test-db
    
    # Start MariaDB temporarily for setup
    echo "Starting MariaDB for initial setup..."
    mariadbd-safe --datadir=/var/lib/mysql --skip-grant-tables --skip-networking &
    
    # Wait for MariaDB to start
    sleep 5
    until mysqladmin ping -hlocalhost --silent; do
        echo 'Waiting for database connection...'
        sleep 2
    done
    
    echo "Setting up clean database and users..."
    # Clean setup - remove all default users and create fresh ones
    mysql << EOF
FLUSH PRIVILEGES;
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF
    
    # Stop MariaDB
    echo "Stopping MariaDB..."
    mysqladmin shutdown
    sleep 2
fi

# Start MariaDB normally
echo "Starting MariaDB normally..."
exec mariadbd-safe --datadir=/var/lib/mysql
