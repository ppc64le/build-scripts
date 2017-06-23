FROM ppc64le/ubuntu:16.04

RUN apt-get update -y && \
        apt-get install -y git libtool libtool-bin automake build-essential&& \
        git clone https://github.com/jemalloc/jemalloc && \
        cd jemalloc && ./autogen.sh && ./configure && \
        make install_bin install_include install_lib && \
        apt-get purge -y git build-essential libtool libtool-bin automake && apt-get autoremove -y

WORKDIR /jemalloc

CMD ["/bin/bash"]
