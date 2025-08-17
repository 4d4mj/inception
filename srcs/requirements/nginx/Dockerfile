FROM alpine:3.18

RUN apk update && apk add --no-cache \
    nginx \
    openssl

COPY conf/nginx.conf /etc/nginx/nginx.conf
COPY tools/setup_ssl.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup_ssl.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/setup_ssl.sh"]
