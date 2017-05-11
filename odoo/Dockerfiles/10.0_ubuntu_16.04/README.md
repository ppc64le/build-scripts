Docker build command:
docker build -t ppc64le/odoo:10.0

Docker pull command:
docker pull ppc64le/odoo:10.0

Sample Docker run command:
This image requires a running PostgreSQL server.
Start a PostgreSQL server
$ docker run -d -e POSTGRES_USER=odoo -e POSTGRES_PASSWORD=odoo --name db ppc64le/postgres:9.4
2)Start an Odoo instance
$ docker run -p 8069:8069 --name odoo --link db:db -t odoo
The alias of the container running Postgres must be db for Odoo to be able to connect to the Postgres server.
3)Stop and restart an Odoo instance
$ docker stop odoo
$ docker start -a odoo
4)Stop and restart a PostgreSQL server
When a PostgreSQL server is restarted, the Odoo instances linked to that server must be restarted as well because the server address has changed
and the link is thus broken.
