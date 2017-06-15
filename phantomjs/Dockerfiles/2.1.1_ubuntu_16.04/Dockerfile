FROM ppc64le/ubuntu:xenial

MAINTAINER "Atul Sowani <sowania@us.ibm.com"

ENV LATEST_STABLE_VERSION=""

#Instakk the dependencies required to build phantomjs from source
RUN apt-get update
RUN apt-get install -y build-essential \
        g++ \
        flex \
        bison \
        gperf \
        ruby \
        perl \
        libsqlite3-dev \
        libfontconfig1-dev \
        libicu-dev \
        libfreetype6 \
        libssl-dev \
        libpng-dev \
        libjpeg-dev \
        python \
        libx11-dev \
        libxext-dev \
        git

#Clone and build the source
RUN git clone git://github.com/ariya/phantomjs.git \
        && cd phantomjs \
        && git checkout 2.1.1 \
        && ./build.py -c

RUN ln -s bin/phantomjs /usr/bin/phantomjs


# Default command
CMD ["/usr/bin/phantomjs"]

