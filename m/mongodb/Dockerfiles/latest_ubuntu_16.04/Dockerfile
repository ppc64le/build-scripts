FROM ppc64le/ubuntu:16.04 
MAINTAINER Vaibhav Sood 
RUN apt-get update && \
    apt-get install -y mongodb-server && \
    mkdir -p /data/db
EXPOSE 27017 28017
CMD ["mongod"]
