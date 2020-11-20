
Docker build command
docker build -t ppc64le/orientdb:3.0.15 .

Docker pull command
docker pull ppc64le/orientdb:3.0.15

Sample Docker run command
docker run -d -p 2424:2424 -p 2480:2480 -e ORIENTDB_ROOT_PASSWORD=rootpwd ppc64le/orientdb:3.0.15

Additional Details available @
https://github.com/docker-library/docs/tree/master/orientdb
