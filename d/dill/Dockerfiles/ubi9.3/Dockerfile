FROM registry.access.redhat.com/ubi9:9.3

MAINTAINER "Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>"

ENV HOME_DIR=${PWD}

ARG PACKAGE_VERSION=0.3.8

RUN yum update -y && \
        yum install -y python3-devel pip gcc gcc-c++ git &&\
        python3 -m pip install coverage numpy pytest tox && \
        cd $HOME_DIR && \
        git clone https://github.com/uqfoundation/dill/ && \
        cd dill && \
        git checkout $PACKAGE_VERSION && \
        python3 setup.py install

CMD ["/bin/bash"]