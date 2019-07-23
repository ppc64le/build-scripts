Docker build command

docker build -t cassandra:3.11 .


Sample Docker run command

docker run -d -p 7000:7000 -p 7001:7001 -p 7199:7199 -p 9042:9042 -p 9160:9160 cassandra:3.11
