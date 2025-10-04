#!/bin/bash

# Read database passwords from Docker secrets
export MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
export MYSQL_PASSWORD=$(cat /run/secrets/db_password)

# Check if database needs initialization (first run)
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing database..."

    # Create SQL script for security setup and database/user creation
    cat > /tmp/init.sql <<EOF
-- Remove anonymous users
DELETE FROM mysql.user WHERE User='';
-- Remove remote root access
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
-- Remove test database
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
-- Create application database and user
CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE;
CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';
FLUSH PRIVILEGES;
EOF

    # Initialize MariaDB data directory
    mysql_install_db --user=mysql \
        --datadir=/var/lib/mysql \
        --auth-root-authentication-method=normal \
        --skip-test-db

    # Start temporary MariaDB instance without networking (using Unix socket)
    mysqld --user=mysql \
        --datadir=/var/lib/mysql \
        --skip-networking \
        --socket=/tmp/mysql.sock &

    # Wait for MariaDB to be ready (up to 30 seconds)
    for i in {1..30}; do
        if mysqladmin --socket=/tmp/mysql.sock ping 2>/dev/null; then
            break
        fi
        echo "Waiting for MariaDB to start... ($i/30)"
        sleep 1
    done

    # Set root password
    mysql --socket=/tmp/mysql.sock <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
FLUSH PRIVILEGES;
EOF

    # Run security SQL script
    mysql --socket=/tmp/mysql.sock -u root -p"$MYSQL_ROOT_PASSWORD" < /tmp/init.sql

    # Shutdown temporary instance
    mysqladmin --socket=/tmp/mysql.sock -u root -p"$MYSQL_ROOT_PASSWORD" shutdown

    wait

    # Clean up
    rm -f /tmp/init.sql

    echo "Database initialization complete"
fi

# Start MariaDB server in foreground
echo "Starting MariaDB server..."
exec mysqld --user=mysql --datadir=/var/lib/mysql --console