FROM ppc64le/ubuntu:16.04

MAINTAINER lysannef@us.ibm.com

ENV DEBIAN_FRONTEND noninteractive
ENV LANG C.UTF-8

ARG PYTHON_VERSION=3.6
ENV PYTHON_VERSION ${PYTHON_VERSION}
ARG LUIGI_VERSION=2.7.6
ENV LUIGI_VERSION ${LUIGI_VERSION}
ENV MINICONDA_VERSION latest
ENV PATH /opt/conda/bin:$PATH
ENV LUIGI_CONFIG_DIR /etc/luigi/
ENV LUIGI_CONFIG_PATH /etc/luigi/luigi.conf
ENV LUIGI_STATE_DIR /luigi/state

RUN apt-get update && apt-get install -y \
        binutils \
        build-essential \
        bzip2 \
        ca-certificates \
        libglib2.0-0 \
        libsm6 \
        libxext6 \
        libxrender1 \
        wget \
        curl \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh && \
    curl -k -o /miniconda.sh https://repo.continuum.io/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-ppc64le.sh && \
    wget https://repo.continuum.io/pkgs/free/linux-ppc64le/luigi-2.3.0-py27_0.tar.bz2 && \
    /bin/bash /miniconda.sh -b -p /opt/conda && \
    rm /miniconda.sh && \
    /opt/conda/bin/conda config \
        --set always_yes yes \
        --set changeps1 no \
        --set show_channel_urls True \
        && \
    /opt/conda/bin/conda config \
        --add channels conda-forge \
        && \
    /opt/conda/bin/conda install \
        python==${PYTHON_VERSION} \
        sqlalchemy \
        psycopg2 \
        mysql-connector-python \
        && \
    /opt/conda/bin/conda install -c anaconda luigi  && \
    /opt/conda/bin/conda clean -a -y && \
    mkdir -p ${LUIGI_CONFIG_DIR} && \
    mkdir -p ${LUIGI_STATE_DIR} && \
    apt-get purge -y binutils build-essential bzip2 ca-certificates libglib2.0-0 libsm6 libxext6  libxrender1 wget curl && \
    apt-get autoremove -y

COPY logging.conf ${LUIGI_CONFIG_DIR}
COPY luigi.conf ${LUIGI_CONFIG_DIR}
VOLUME ["${LUIGI_CONFIG_DIR}", "${LUIGI_STATE_DIR}"]

EXPOSE 8082/TCP

RUN cd /etc/luigi && mkdir luigid && cd luigid && mkdir run
COPY luigid.sh /etc/service/luigid/run/
