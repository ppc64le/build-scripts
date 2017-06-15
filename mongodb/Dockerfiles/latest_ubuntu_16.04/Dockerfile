FROM ppc64le/ubuntu:16.04 
MAINTAINER Vaibhav Sood 
RUN echo "deb http://ports.ubuntu.com/ubuntu-ports/ xenial universe"  | tee /etc/apt/sources.list.d/ubuntu-xenial.list && \
    echo "deb http://ports.ubuntu.com/ubuntu-ports/ xenial-updates universe" | tee /etc/apt/sources.list.d/ubuntu-xenial-updates.list && \
    apt-get update && \
    apt-get install -y mongodb-server && \
    mkdir -p /data/db
EXPOSE 27017 28017
CMD ["mongod"]
