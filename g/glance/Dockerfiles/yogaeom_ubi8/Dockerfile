FROM registry.access.redhat.com/ubi8/ubi:8.7

MAINTAINER "Vinod K <Vinod.K1@ibm.com>"

ARG PACKAGE_VERSION=yoga-eom

RUN yum install -y git wget gcc gcc-c++ python39 python39-pip python39-devel python39-psycopg2 libxslt libxslt-devel make libpq libpq-devel openssl-devel cmake xz libaio pixman pixman-devel

RUN wget https://static.rust-lang.org/dist/rust-1.65.0-powerpc64le-unknown-linux-gnu.tar.gz  &&\
    tar -xzf rust-1.65.0-powerpc64le-unknown-linux-gnu.tar.gz  && \
    cd rust-1.65.0-powerpc64le-unknown-linux-gnu  && \
    ./install.sh  && \
    cd ..

RUN git clone https://github.com/openstack/glance && \
    cd glance && \
    git checkout $PACKAGE_VERSION && \
    pip3 install "cython<3.0.0" wheel tox && pip3 install --no-build-isolation pyyaml==6.0 && \
    python3 -m pip install -r requirements.txt

CMD ["/bin/bash"]
