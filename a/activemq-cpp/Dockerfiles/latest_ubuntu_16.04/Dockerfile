FROM ppc64le/ubuntu:16.04

MAINTAINER "Atul Sowani <sowania@us.ibm.com>"

ENV TZ="America/New_York"

RUN apt-get update -y && \
    apt-get install -y git libtool autoconf build-essential cmake \
        libapr1-dev libcppunit-dev uuid-dev tzdata doxygen && \
    git clone https://github.com/apache/activemq-cpp && \
    cd activemq-cpp/activemq-cpp && \
    ./autogen.sh && \
    ./configure && \
    make && \
    make check && \
    echo "America/New_York" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata && \
    ./src/test/activemq-test && \
    apt-get remove --purge -y git autoconf libtool cmake doxygen \
        build-essential libapr1-dev uuid-dev && \
    apt-get autoremove -y

CMD ["/bin/bash"]
