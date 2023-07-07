How to run the Odoo container from built image:
-------------

- Run Postgres container:

    `docker run -d -e POSTGRES_USER=odoo -e POSTGRES_PASSWORD=odoo -e POSTGRES_DB=postgres --name db postgres:latest`

- Run Odoo container using image:

    `docker run -p 8069:8069 --name Odoo --link db:db -it ibmcom/odoo-ppc64le:16.0`
