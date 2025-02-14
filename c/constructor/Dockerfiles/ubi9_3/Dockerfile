FROM registry.access.redhat.com/ubi9:9.3

MAINTAINER "Stuti Wali <Stuti.Wali@ibm.com>"

ARG PACKAGE_VERSION=3.7.0
ENV SOURCE_DIR=$PWD
ENV PATH=/usr/local/bin:$PATH

RUN yum install -y gcc gcc-c++ make cmake git wget  autoconf automake libtool pkgconf-pkg-config info gzip tar bzip2 zip unzip xz zlib-devel yum-utils fontconfig fontconfig-devel openssl-devel  fontconfig fontconfig-devel  ncurses-devel python3-setuptools

RUN wget https://www.python.org/ftp/python/3.8.12/Python-3.8.12.tgz && \
    tar xzf Python-3.8.12.tgz && \
    cd Python-3.8.12 && \
    ./configure --prefix=/opt/python3.8 --enable-optimizations && \
    make -j4 && \
    make altinstall && \
    ln -s /opt/python3.8/bin/python3.8 /usr/local/bin/python3.8 && \
    python3.8 --version && \
    cd .. 


RUN cd $SOURCE_DIR && \
    git clone https://github.com/conda/constructor && \
    cd constructor && \
    git checkout $PACKAGE_VERSION && \
    cd ..

RUN wget https://repo.anaconda.com/miniconda/Miniconda3-py38_4.9.2-Linux-ppc64le.sh -O miniconda.sh && \
    bash miniconda.sh -b -p $HOME/miniconda

ENV PATH="/root/miniconda/bin:$PATH"

RUN /root/miniconda/condabin/conda config --add channels conda-forge && \
    cd $SOURCE_DIR && \
    conda env create -n constructor-dev -f constructor/dev/environment.yml && \
    conda init bash && \
    eval "$(conda shell.bash hook)" && \
    conda activate constructor-dev && \
    pip install pytest pytest-cov coverage jinja2 && \
    yum install -y python3-ruamel-yaml-clib.ppc64le

ENV PATH="$HOME/miniconda/bin:$PATH"
ENV LD_LIBRARY_PATH=/usr/lib64
ENV PATH=$LD_LIBRARY_PATH:$PATH

RUN cd $SOURCE_DIR && \
    cd constructor && \
    python3 setup.py build && \
    python3 setup.py install

CMD ["bash"]