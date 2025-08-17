FROM alpine:3.18

RUN apk update && apk add --no-cache \
    php82-fpm \
    php82-mysqli \
    php82-gd \
    php82-xml \
    php82-mbstring \
    php82-zip \
    php82-curl \
    php82-phar \
    php82-cli \
    wget \
    curl \
    netcat-openbsd \
    bash

# Create www-data user if it doesn't exist
RUN addgroup -g 82 -S www-data 2>/dev/null || true
RUN adduser -u 82 -D -S -G www-data www-data 2>/dev/null || true

# Create symlink for php command
RUN ln -s /usr/bin/php82 /usr/bin/php

# Create PHP run directory
RUN mkdir -p /run/php
RUN chown www-data:www-data /run/php

# Install WordPress CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

COPY conf/php-fpm.conf /etc/php82/php-fpm.d/www.conf
COPY tools/setup_wp.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup_wp.sh

WORKDIR /var/www/wordpress
EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/setup_wp.sh"]
