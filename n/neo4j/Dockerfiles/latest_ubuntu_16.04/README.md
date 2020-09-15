Neo4j

Building and running the Dockerfile

$ docker build -t neo4j .
$ docker run \
    --publish=7474:7474 --publish=7687:7687 \
    --volume=$HOME/neo4j/data:/data \
    neo4j

Now you can access the neo4j dashboard from browser at 
http://vm_ip:7474

Default username and passwords are neo4j/neo4j
After entering the password "neo4j", you will get a prompt to change the
password. After this you will be able to access the dashboard.
