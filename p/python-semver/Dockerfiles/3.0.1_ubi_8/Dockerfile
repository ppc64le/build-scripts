FROM registry.access.redhat.com/ubi8/ubi:8.7

MAINTAINER "Pratik Tonage <Pratik.Tonage@ibm.com>"

ARG PACKAGE_VERSION=3.0.1
ARG PACKAGE_NAME=python-semver
ARG PACKAGE_URL=https://github.com/python-semver/python-semver

RUN yum update -y && \
    yum install git gcc gcc-c++ make python39 python39-devel -y && \
    git clone $PACKAGE_URL && \
    cd PACKAGE_NAME && \
    git checkout $PACKAGE_VERSION && \
    python3 -m pip install --upgrade pip && \
    python3 -m pip install tox tox-gh-actions && \
	python3 -m pip install .
    
CMD ["/bin/bash"]
