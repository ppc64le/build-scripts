FROM registry.access.redhat.com/ubi8/ubi:8.7

MAINTAINER "Vinod K <Vinod.K1@ibm.com>"

ARG PACKAGE_VERSION=1.2.4

RUN yum install -y git wget gcc gcc-c++ python39 python39-pip python39-devel yum-utils make automake autoconf libtool gdb* binutils rpm-build gettext && \
    python3 -m ensurepip --upgrade && \
    export PATH=$PATH:/usr/local/bin


RUN git clone https://github.com/ilanschnell/bsdiff4 && \
    cd bsdiff4/ && \
    git checkout $PACKAGE_VERSION && \
    python3 -m pip install -e .

CMD ["/bin/bash"]
