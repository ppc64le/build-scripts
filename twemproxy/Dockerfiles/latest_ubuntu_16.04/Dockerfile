FROM ppc64le/ubuntu:16.04
MAINTAINER "Atul Sowani <sowania@us.ibm.com>"
RUN apt-get update -y && \
        apt-get install -y git gcc libtool autoconf make && \
        git clone https://github.com/twitter/twemproxy && \
        cd twemproxy && \
        autoreconf -fvi && \
        ./configure --build=ppc64le-redhat-linux --enable-debug=full && \
        make && make install && \
        apt-get -y purge git gcc libtool autoconf make && apt-get autoremove -y
WORKDIR /twemproxy
CMD ["/bin/bash"]
