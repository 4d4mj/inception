#!/bin/bash

# Read secrets from Docker secrets and export as environment variables
export MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
export MYSQL_PASSWORD=$(cat /run/secrets/db_password)

# Check if database has been initialized
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing database..."
    
    # Create initialization SQL file
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
    
    # Initialize database with root password
    mysql_install_db --user=mysql \
        --datadir=/var/lib/mysql \
        --auth-root-authentication-method=normal \
        --skip-test-db
    
    # Start temporary server to execute init script
    mysqld --user=mysql \
        --datadir=/var/lib/mysql \
        --skip-networking \
        --socket=/tmp/mysql.sock &
    
    # Wait for server to start
    for i in {1..30}; do
        if mysqladmin --socket=/tmp/mysql.sock ping 2>/dev/null; then
            break
        fi
        echo "Waiting for MariaDB to start... ($i/30)"
        sleep 1
    done
    
    # Set root password and run initialization
    mysql --socket=/tmp/mysql.sock <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
FLUSH PRIVILEGES;
EOF
    
    # Run the rest of initialization with password
    mysql --socket=/tmp/mysql.sock -u root -p"$MYSQL_ROOT_PASSWORD" < /tmp/init.sql
    
    # Shutdown temporary server
    mysqladmin --socket=/tmp/mysql.sock -u root -p"$MYSQL_ROOT_PASSWORD" shutdown
    
    # Wait for shutdown
    wait
    
    # Clean up
    rm -f /tmp/init.sql
    
    echo "Database initialization complete"
fi

echo "Starting MariaDB server..."
# Start MariaDB in foreground
exec mysqld --user=mysql --datadir=/var/lib/mysql --console