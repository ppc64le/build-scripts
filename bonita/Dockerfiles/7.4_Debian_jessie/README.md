How to use this image
1)Quick start
$ docker run --name bonita -d -p 8080:8080 bonita
This will start a container running the Tomcat Bundle with Bonita BPM Engine + Bonita BPM Portal. 
With no environment variables specified, it's as like if you have launched the bundle on your host using startup.{sh|bat} 
(with security hardening on REST and HTTP APIs, cf Security part). Bonita BPM uses a H2 database here.

You can access the Bonita BPM Portal on http://<localhost>:8080/bonita and login using the default credentials: install / install

2)Link Bonita BPM to a database

I)PostgreSQL
PostgreSQL is the recommended database. Link to ppc64le PostgreSQL image (https://hub.docker.com/r/ppc64le/postgres/)

Set max_prepared_transactions to 100:

mkdir -p custom_postgres
echo '#!/bin/bash' > custom_postgres/bonita.sh
echo 'sed -i "s/^.*max_prepared_transactions\s*=\s*\(.*\)$/max_prepared_transactions = 100/" "$PGDATA"/postgresql.conf' >> custom_postgres/bonita.sh
chmod +x custom_postgres/bonita.sh
Mount that directory location as /docker-entrypoint-initdb.d inside the PostgreSQL container:

$ docker run --name mydbpostgres -v "$PWD"/custom_postgres/:/docker-entrypoint-initdb.d -e POSTGRES_PASSWORD=mysecretpassword -d ppc64le/postgres:9.4

See the official PostgreSQL documentation for more details.

$ docker run --name bonita_postgres --link mydbpostgres:postgres -d -p 8080:8080 bonita

II)MySQL database Link to ppc64le MySQL image (https://hub.docker.com/r/ppc64le/mariadb/)

Increase the packet size which is set by default to 1M:
mkdir -p custom_mysql
echo "[mysqld]" > custom_mysql/bonita.cnf
echo "max_allowed_packet=16M" >> custom_mysql/bonita.cnf

Mount that directory location as /etc/mysql/conf.d inside the MySQL container:
$ docker run --name mydbmysql -v "$PWD"/custom_mysql/:/etc/mysql/conf.d -e MYSQL_ROOT_PASSWORD=mysecretpassword -d ppc64le/mariadb:10.1

Start your application container to link it to the MySQL container:
$ docker run --name bonita_mysql --link mydbmysql:mysql -d -p 8080:8080 bonita
