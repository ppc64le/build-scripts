FROM registry.access.redhat.com/ubi9/ubi:9.3

MAINTAINER Vipul Ajmera <Vipul.Ajmera@ibm.com>

ARG PACKAGE_VERSION=3.0.2

RUN yum install -y yum-utils git gcc gcc-c++ make python3.11 python3.11-pip python3.11-devel && \
    git clone https://github.com/python-semver/python-semver.git && \
    cd python-semver && \
    git checkout $PACKAGE_VERSION && \
    python3.11 -m pip install --upgrade pip && \
    python3.11 -m pip install tox tox-gh-actions && \
    python3.11 -m pip install build && \
    python3.11 -m pip install -r docs/requirements.txt && \
    pyproject-build
    
CMD ["/bin/bash"]
