FROM ppc64le/ubuntu:16.04

RUN apt-get update -y && \
        apt-get install -y git libtool  pkg-config autoconf automake build-essential gettext && \
        git clone https://github.com/jedisct1/libsodium.git && \
        cd libsodium && ./autogen.sh && ./configure && make && \
        make check && sudo make install

CMD ["/bin/bash"]
