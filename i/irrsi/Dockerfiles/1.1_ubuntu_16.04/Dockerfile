FROM ppc64le/ubuntu:16.04

MAINTAINER Yugandha Deshpande <yugandha@us.ibm.com>


RUN echo "deb http://ports.ubuntu.com/ubuntu-ports/ xenial universe" >> /etc/apt/sources.list && \
    apt-get update && apt-get install -y git \
        autoconf \
        libtool \
        libglib2.0-dev \
        libglib2.0-0 \
        libncurses5-dev \
        lynx \
        libssl-dev && \
    export HOME=/home/irssiUser && \
    useradd --create-home --home-dir $HOME irssiUser \
    && mkdir -p $HOME/.irssi \
    && chown -R irssiUser:irssiUser $HOME && \
    git clone https://github.com/irssi/irssi.git && cd irssi && bash -c "./autogen.sh" && make && make install && \
    echo "nameserver 8.8.8.8" >> /etc/resolv.conf && \
    cd .. && rm -rf irssi && \
    apt-get purge -y git \
        autoconf \
        libtool
ENV HOME /home/irssiUser
WORKDIR $HOME
USER irssiUser
VOLUME $HOME/.irssi
CMD ["irssi"]
