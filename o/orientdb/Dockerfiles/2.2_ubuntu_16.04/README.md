Upstream Dockerfile (ppc64le)
https://raw.githubusercontent.com/orientechnologies/orientdb-docker/master/2.2/ppc64le/ubuntu/Dockerfile

Docker build command
docker build -t ppc64le/orientdb:2.2.19 .

Docker pull command
docker pull ppc64le/orientdb:2.2.19

Sample Docker run command
docker run -d -p 2424:2424 -p 2480:2480 -e ORIENTDB_ROOT_PASSWORD=rootpwd ppc64le/orientdb:2.2.19

Additional Details available @
https://github.com/docker-library/docs/tree/master/orientdb
