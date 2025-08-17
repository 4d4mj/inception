FROM alpine:3.18

RUN apk update && apk add --no-cache \
    mariadb \
    mariadb-client \
    bash

RUN mkdir -p /etc/my.cnf.d /var/lib/mysql /run/mysqld
RUN chown -R mysql:mysql /var/lib/mysql /run/mysqld
COPY conf/mariadb.conf /etc/my.cnf.d/mariadb-server.cnf
RUN chmod 644 /etc/my.cnf.d/mariadb-server.cnf
COPY tools/init_db.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init_db.sh

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/init_db.sh"]
