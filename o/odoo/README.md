How to run the Odoo server:
-------------

The Odoo server requires Postgres to run successfully however Postgres is not able to install and run within a UBI container. Hence we need to use a Postgres container integrated with the UBI container used to build Odoo.

*************************

- Create a user-defined docker network:
    
    `docker network create odoo-net`

- Create and run a container using a Postgres image:
    
    `docker run --name db --network odoo-net -e POSTGRES_USER=odoo -e POSTGRES_PASSWORD=odoo -p 5432:5432 -it postgres`

- In a different shell, connect to the Postgres container as non-root user and create a database:

    `docker exec -it db psql -U odoo`  
    `create databse mydb;`

- Create and run UBI container to build Odoo:
    
    `docker run -it --name odoo --network odoo-net registry.access.redhat.com/ubi8/ubi:latest /bin/bash`

- Retrieve IPAddress of Postgres container using:

    `docker inspect db`

- Use the IPAddress from above to run the Odoo server:

    `python3.10 odoo-bin -d mydb -r odoo -w odoo --db_host <IPAddress> --db_port 5432 -i INIT`