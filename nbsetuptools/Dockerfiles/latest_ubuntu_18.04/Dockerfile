FROM ubuntu:18.04

MAINTAINER Priya Seth <sethp@us.ibm.com>

RUN apt-get update -y && \

# Installing dependent packages
    apt-get install -y build-essential software-properties-common \
    	python-setuptools python-dev python-pip git && \
    	pip install pytest && \

#Clone repo and build
    git clone https://github.com/Anaconda-Platform/nbsetuptools.git && \
    cd nbsetuptools && \
    pip install . && \
    python setup.py install  && \
    pytest -k "not test_enable" && \

    apt-get remove -y git && apt-get -y purge && \
    apt-get -y autoremove && \
    cd .. && rm -rf nbsetuptools
