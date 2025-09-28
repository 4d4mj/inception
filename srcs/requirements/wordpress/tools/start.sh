#!/bin/bash
set -e

# Read secrets from Docker secrets
MYSQL_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

mkdir -p /var/www/html
cd /var/www/html

# Install WordPress command-line tool if not already available
if ! command -v wp >/dev/null 2>&1; then
    curl -fsSL -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x /usr/local/bin/wp
fi

# Wait for MariaDB to be ready
until mysql -h mariadb -u "${MYSQL_USER}" -p"${MYSQL_PASSWORD}" -e "SELECT 1" > /dev/null 2>&1; do
    echo "Waiting for MariaDB to be ready..."
    sleep 3
done

# Download WordPress and prepare configuration if not already set up
if [ ! -f wp-config.php ]; then
    wp core download --allow-root
    wp config create --dbname="${MYSQL_DATABASE}" \
                     --dbuser="${MYSQL_USER}" \
                     --dbpass="${MYSQL_PASSWORD}" \
                     --dbhost=mariadb:3306 \
                     --allow-root
fi

# Install WordPress with environment-provided data when needed
if ! wp core is-installed --allow-root >/dev/null 2>&1; then
    wp core install --url="https://${DOMAIN_NAME}" \
                    --title="${WP_TITLE}" \
                    --admin_user="${WP_ADMIN_USER}" \
                    --admin_password="${WP_ADMIN_PASSWORD}" \
                    --admin_email="${WP_ADMIN_EMAIL}" \
                    --skip-email \
                    --allow-root
fi

# Ensure the additional WordPress user exists
if ! wp user get "${WP_USER}" --allow-root >/dev/null 2>&1; then
    wp user create "${WP_USER}" "${WP_USER_EMAIL}" \
                   --user_pass="${WP_USER_PASSWORD}" \
                   --role=author \
                   --allow-root
fi

# Keep WordPress URLs aligned to HTTPS
wp option update home "https://${DOMAIN_NAME}" --allow-root
wp option update siteurl "https://${DOMAIN_NAME}" --allow-root

# Configure PHP-FPM and launch service
sed -i 's/listen = \/run\/php\/php8.2-fpm.sock/listen = 9000/g' /etc/php/8.2/fpm/pool.d/www.conf
mkdir -p /run/php
php-fpm8.2 -F
