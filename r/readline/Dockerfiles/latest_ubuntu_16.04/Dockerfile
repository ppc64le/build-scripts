#Dockerfile for building "readline" on Ubuntu16.04
FROM ppc64le/ubuntu:16.04
MAINTAINER Archa Bhandare <barcha@us.ibm.com>

#Clone repo and build
RUN apt-get update -y && apt-get install -y git cmake \
    && git clone https://github.com/Distrotech/readline \
    && cd readline && ./configure --build=ppc64le-linux --prefix=/usr/local --with-curses && make && make install \
    && cd .. && apt-get remove -y git cmake && apt-get -y autoremove && rm -rf readline

CMD ["/bin/bash"]
