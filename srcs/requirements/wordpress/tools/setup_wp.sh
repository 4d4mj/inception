#!/bin/bash

# Wait for database
echo "Waiting for database connection..."
until nc -z mariadb 3306; do
    echo "Database not ready yet, waiting..."
    sleep 3
done

echo "Database is ready, proceeding with WordPress setup..."

# Create WordPress directory if it doesn't exist
mkdir -p /var/www/wordpress
cd /var/www/wordpress

# Change ownership
chown -R www-data:www-data /var/www/wordpress

# Download WordPress if not exists
if [ ! -f wp-config.php ]; then
    echo "Downloading WordPress..."
    # Set higher memory limit for wp-cli
    export PHP_MEMORY_LIMIT=512M
    
    # Download WordPress with higher memory limit
    php -d memory_limit=512M /usr/local/bin/wp core download --allow-root

    echo "Creating wp-config.php..."
    # Create wp-config.php
    php -d memory_limit=512M /usr/local/bin/wp config create \
        --dbname=${MYSQL_DATABASE} \
        --dbuser=${MYSQL_USER} \
        --dbpass=${MYSQL_PASSWORD} \
        --dbhost=mariadb:3306 \
        --allow-root

    echo "Installing WordPress..."
    # Install WordPress
    php -d memory_limit=512M /usr/local/bin/wp core install \
        --url=https://${DOMAIN_NAME} \
        --title="Inception WordPress" \
        --admin_user=${WP_ADMIN_USER} \
        --admin_password=${WP_ADMIN_PASSWORD} \
        --admin_email=${WP_ADMIN_EMAIL} \
        --allow-root

    echo "Creating additional user..."
    # Create additional user
    php -d memory_limit=512M /usr/local/bin/wp user create \
        ${WP_USER} \
        ${WP_USER_EMAIL} \
        --user_pass=${WP_USER_PASSWORD} \
        --allow-root

    echo "WordPress setup completed!"
fi

# Ensure proper ownership
chown -R www-data:www-data /var/www/wordpress

# Start PHP-FPM
echo "Starting PHP-FPM..."
mkdir -p /run/php
exec php-fpm82 -F
