FROM registry.access.redhat.com/ubi9:9.3

MAINTAINER "Stuti Wali <Stuti.Wali@ibm.com>"

ARG PACKAGE_VERSION=v1.3.8

ENV SOURCE_DIR=$PWD
ENV PATH=/usr/local/bin:$PATH

RUN yum install -y python3 git gcc gcc-c++ python3-devel python3-setuptools python3-test wget sqlite sqlite-devel libxml2-devel libxslt-devel make cmake && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    
ENV PATH="$HOME/.cargo/bin:$PATH"

RUN source ~/.bashrc && \
    rustc --version && \
    pip3 install --upgrade setuptools virtualenv mock ipython_genutils pytest traitlets numpy


RUN cd $SOURCE_DIR && \
    git clone https://github.com/pydata/bottleneck && \
    cd bottleneck && \
    git checkout $PACKAGE_VERSION && \
    python3 setup.py install

CMD ["bash"]
