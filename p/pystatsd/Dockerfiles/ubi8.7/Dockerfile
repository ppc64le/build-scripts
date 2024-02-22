FROM registry.access.redhat.com/ubi8/ubi:8.7

MAINTAINER "Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>"

ENV HOME_DIR=${PWD}

ARG PACKAGE_VERSION=v4.0.1

RUN yum update -y && \
        yum install -y git python38 python38-devel && \
		pip3 install tox && \
        git clone https://github.com/jsocol/pystatsd && \
        cd pystatsd && \
		git checkout $PACKAGE_VERSION && \
        pip3 install .

CMD ["/bin/bash"]