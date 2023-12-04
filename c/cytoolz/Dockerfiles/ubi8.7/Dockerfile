FROM registry.access.redhat.com/ubi8/ubi:8.7

MAINTAINER "Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>"

ENV HOME_DIR=${PWD}

ARG PACKAGE_VERSION=0.12.2

RUN yum update -y && \
        yum install -y python39-devel.ppc64le gcc git && \
        python3 -m pip install --upgrade pip setuptools wheel && \
        python3 -m pip install cython pytest git+https://github.com/pytoolz/toolz.git && \
        git clone https://github.com/pytoolz/cytoolz && \
        cd cytoolz && \
        git checkout $PACKAGE_VERSION && \
        python3 setup.py build_ext --inplace --with-cython && \
        pip install -e .

CMD ["/bin/bash"]