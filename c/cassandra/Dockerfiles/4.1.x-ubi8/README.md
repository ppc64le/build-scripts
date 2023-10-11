Check the latest 4.0.x version available @ https://downloads.apache.org/cassandra/redhat/40x/ And use that as TAG and VERSION_ARG in the following docker command to build the image:

docker build --pull --no-cache -t cassandra:<TAG> --build-arg VERSION=<VERSION_ARG> .

Sample docker run command:

docker run -d -p 7000:7000 -p 7001:7001 -p 7199:7199 -p 9042:9042 -p 9160:9160 cassandra:<TAG>

Validation using the cqlsh command:

docker exec -it <CONTAINER_NAME> cqlsh --version
