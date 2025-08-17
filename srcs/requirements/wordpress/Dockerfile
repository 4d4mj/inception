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
    wget \
    curl \
    netcat-openbsd

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
