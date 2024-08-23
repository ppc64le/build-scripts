FROM registry.access.redhat.com/ubi9/ubi:9.3

MAINTAINER "Ramnath Nayak <Ramnath.Nayak@ibm.com>"

ENV HOME_DIR=${PWD}
ARG PACKAGE_VERSION=6.0

RUN yum update -y && \
        yum install -y git gcc gcc-c++ yum-utils make automake autoconf libtool gdb* binutils rpm-build gettext wget && \
        yum install -y libffi-devel libpq-devel -y && \
        yum install -y python3 python3-devel python3-setuptools && \
        python3 -m ensurepip --upgrade && \
        python3 -m pip install tox --ignore-installed && \
        git clone https://github.com/zopefoundation/BTrees.git && \
        cd BTrees && \
        git checkout $PACKAGE_VERSION && \
        python3 setup.py build

CMD ["/bin/bash"]
