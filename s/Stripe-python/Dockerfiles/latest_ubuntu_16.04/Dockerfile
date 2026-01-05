## Initial Image Details
FROM ubuntu:16.04

## Author of the new image
MAINTAINER Archa Bhandare

ENV DEBIAN_FRONTEND noninteractive

## Update source, Install dependencies, Clone repo
RUN echo 'deb http://ports.ubuntu.com/ubuntu-ports xenial restricted multiverse universe' >> /etc/apt/sources.list && apt-get -y update && \
   apt-get install -y build-essential software-properties-common libssl-dev libffi-dev git python-setuptools python-dev locales locales-all && \
	easy_install pip && pip install --upgrade setuptools virtualenv && \
	git clone https://github.com/stripe/stripe-python && cd stripe-python && \
        git checkout v1.77.0 

## Build and Install
WORKDIR stripe-python/
RUN export TOXENV=py27 && virtualenv -p python2 --system-site-packages env2 && /bin/bash -c "source env2/bin/activate" && pip install -U setuptools pip && pip install unittest2 mock flake8 tox tox-travis && python setup.py install && flake8 stripe && python -W always setup.py test
RUN  pip uninstall -y unittest2 mock flake8 tox tox-travis && apt-get remove -y git && apt-get -y purge && apt-get -y autoremove
