FROM ppc64le/ubuntu:16.04
MAINTAINER "Atul Sowani <sowania@us.ibm.com>"

RUN apt-get update -y && \
    apt-get install -y automake libtool \
        libdb5.3-dev libsasl2-dev zlib1g-dev libssl-dev libpcre3-dev \
        uuid-dev comerr-dev libcunit1-dev valgrind libsnmp-dev \
        bison flex libjansson-dev shtool pkg-config wget && \
    wget ftp://ftp.cyrusimap.org/cyrus-sasl/cyrus-sasl-2.1.26.tar.gz && \
    tar -xzvf cyrus-sasl-2.1.26.tar.gz && \
    cd cyrus-sasl-2.1.26 && ./configure --build ppc64le && make && \
    make check && make install && \
    apt-get remove -y --purge automake libtool libdb5.3-dev libsasl2-dev \
        zlib1g-dev libssl-dev libpcre3-dev uuid-dev comerr-dev libcunit1-dev \
        valgrind libsnmp-dev bison flex libjansson-dev shtool \
        wget pkg-config && \
    apt-get autoremove -y && \
    rm -rf /cyrus-sasl-2.1.26.tar.gz /cyrus-sasl-2.1.26

CMD bash
