FROM alpine:3.18

RUN apk update && apk add --no-cache \
    mariadb \
    mariadb-client

COPY conf/mariadb.conf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY tools/init_db.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init_db.sh

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/init_db.sh"]
