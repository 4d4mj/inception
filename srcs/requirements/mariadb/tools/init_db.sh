#!/bin/bash

# Initialize MySQL data directory if it doesn't exist
if [ ! -d "/var/lib/mysql/mysql" ]; then
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
fi

# Start MySQL in background
mysqld_safe --datadir=/var/lib/mysql &

# Wait for MySQL to start
until mysqladmin ping -hlocalhost --silent; do
    echo 'Waiting for database connection...'
    sleep 2
done

# Create database and users
mysql -e "CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};"
mysql -e "CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
mysql -e "GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';"
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"
mysql -e "FLUSH PRIVILEGES;"

# Stop background MySQL and start foreground
mysqladmin shutdown
exec mysqld_safe --datadir=/var/lib/mysql
