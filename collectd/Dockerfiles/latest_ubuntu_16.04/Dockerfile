FROM  ppc64le/ubuntu:16.04

MAINTAINER Snehlata Mohite <smohite@us.ibm.com>

RUN  apt-get update \
    && apt-get install -y --no-install-recommends collectd  

CMD  ["collectd", "-f"]


