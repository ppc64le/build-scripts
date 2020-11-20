FROM ppc64le/ubuntu:xenial

# Maintainer name
MAINTAINER "Amitkumar Ghatwal <ghatwala@us.ibm.com>"

# Adding Ubuntu repository to sources file
RUN echo deb http://ports.ubuntu.com/ubuntu-ports xenial restricted main multiverse universe  >> /etc/apt/sources.list

# install dependent packages
RUN apt-get update -y && \
    apt-get install -y git \
        libboost-all-dev \
        libpcre3 \
        libpcre3-dev \
        yodl \
        ruby \
        ruby-dev \
        ocaml \
        automake \
        bison \
        byacc \
        build-essential && \
    git clone https://github.com/swig/swig.git && \
    cd swig && \
    ./autogen.sh && \
    ./configure --without-ocaml && \
    make && \
    make install && \
    make check-perl5-test-suite && \
    rm -rf ../swig && \
    apt-get remove --purge -y \
        libboost-all-dev \
        libpcre3-dev \
        ruby-dev \
        automake \
        build-essential && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

# Creating volume directory so we can share data between container and host
VOLUME /data

#setting entry point to, so we can RUN docker image as command.
ENTRYPOINT ["swig"]

