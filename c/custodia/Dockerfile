FROM ubuntu:xenial
MAINTAINER "Eshant Gupta <guptaeshant@gmail.com>"
ENV TOXENV=py36-noextras
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'
WORKDIR /root
RUN \
    # Install dependencies
    apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update  && \
    apt-get install -yq --no-install-suggests \
            python3.6 python3.6-dev python3-pip git enchant locales \
            libffi-dev libssl-dev && \
    apt-get clean && apt-get autoremove -y && \
    #locale for en_US
    locale-gen en_US.UTF-8 && \
    ln -sf python3.6 /usr/bin/python3 && \
    # Clone Project
    git clone https://github.com/latchset/custodia.git custodia && \
    cd custodia && \
    # update pip
    python3 -m pip install --upgrade pip setuptools && \
    python3 -m pip install tox && \
    tox
