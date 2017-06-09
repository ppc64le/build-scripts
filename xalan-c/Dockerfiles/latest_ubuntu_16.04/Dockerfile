FROM ppc64le/ubuntu:16.04
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

RUN echo "deb http://in.ports.ubuntu.com/ubuntu-ports/ xenial universe" >> /etc/apt/sources.list && \
    apt-get update -y && \
    apt-get install libxalan-c111 xalan -y
CMD ["/bin/bash"]

