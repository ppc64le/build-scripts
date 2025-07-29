FROM registry.access.redhat.com/ubi9/ubi:9.3

MAINTAINER "Vipul Ajmera <Vipul.Ajmera@ibm.com>"

ARG PACKAGE_VERSION=v10.5.0

RUN yum install -y git gcc gcc-c++ make wget openssl-devel bzip2-devel libffi-devel zlib-devel

RUN wget https://static.rust-lang.org/dist/rust-1.75.0-powerpc64le-unknown-linux-gnu.tar.gz && \
    tar -xzf rust-1.75.0-powerpc64le-unknown-linux-gnu.tar.gz && \
    cd rust-1.75.0-powerpc64le-unknown-linux-gnu && \
    ./install.sh && \
    export PATH=$HOME/.cargo/bin:$PATH && \
    cd ../ 

RUN wget https://www.python.org/ftp/python/3.10.0/Python-3.10.0.tgz && \
    tar xzf Python-3.10.0.tgz && \
    cd Python-3.10.0 && \
    ./configure --enable-optimizations &&\
    make -j 4 && \
    make altinstall && \
    export PATH=$PATH:/usr/local/bin && \
    cd ../ 

RUN git clone https://github.com/stripe/stripe-python.git && \
    cd stripe-python && \
    git checkout $PACKAGE_VERSION && \
    python3.10 -m pip install pip wheel && \
    python3.10 -m pip install pytest tox && \
    python3.10 -m pip install -r requirements.txt && \
    python3.10 -m pip install -r test-requirements.txt && \
    python3.10 setup.py install 

CMD ["/bin/bash"]	
