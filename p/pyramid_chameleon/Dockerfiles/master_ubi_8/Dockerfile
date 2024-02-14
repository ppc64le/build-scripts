FROM registry.access.redhat.com/ubi8/ubi:8.7

MAINTAINER "Mohit Pawar <Mohit.Pawar@ibm.com>"

ARG PACKAGE_VERSION=master

RUN yum update -y && \
        yum install -y git gcc gcc-c++ yum-utils make automake autoconf libtool gdb* binutils rpm-build gettext wget && \
        yum install -y libffi-devel libpq-devel -y && \
        yum install -y python39 python39-devel python39-setuptools && \
        python3 -m ensurepip --upgrade && \ 
        pip3 install tox build && \
        python3 -m pip install pytest && \
        git clone https://github.com/Pylons/pyramid_chameleon && \
        cd pyramid_chameleon && \
        python3 setup.py install 

CMD ["/bin/bash"]
