#Dockerfile for building "headers_workaround" on Ubuntu16.04

FROM ppc64le/ubuntu:18.04

MAINTAINER Priya Seth <sethp@us.ibm.com>

RUN apt-get update -y &&\

# Installing dependent packages
    apt-get install -y python-setuptools python-dev python-pip git && \
    pip install -U setuptools pytest && \

#Clone repo and build
    git clone https://github.com/syllog1sm/headers_workaround.git && cd headers_workaround && \
    python setup.py install && py.test && \
    cd .. && apt-get remove -y git && apt-get -y purge && \
    apt-get -y autoremove && rm -rf headers_workaround 
