FROM ubuntu:20.04

MAINTAINER "Amir Sanjar <amir.sanjar@ibm.com>
ENV DEBIAN_FRONTEND noninteractive

RUN  apt-get update -y \
     && apt-get install -y git autoconf libtool automake g++ make curl unzip \
     && apt install openjdk-11-jdk maven -y

CMD ["bash"]

