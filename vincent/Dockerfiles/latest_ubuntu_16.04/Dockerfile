## Initial Image Details
FROM ppc64le/ubuntu:16.04

## Author of the new image
MAINTAINER Archa Bhandare

ENV DEBIAN_FRONTEND noninteractive

## Update source, Install dependencies, Clone repo
RUN echo 'deb http://ports.ubuntu.com/ubuntu-ports xenial restricted multiverse universe' >> /etc/apt/sources.list && \
	apt-get -y update && apt-get install -y build-essential software-properties-common && \
	apt-get install -y git python-setuptools python-dev locales locales-all && \
	easy_install pip && pip install --upgrade setuptools virtualenv && \
	git clone https://github.com/wrobstory/vincent

## Build and Install
WORKDIR vincent/
RUN apt-get install -qq gfortran libatlas-base-dev python-numpy && \
	pip install ipython mock pandas flake8 pytest nose ptyprocess && pip install -r requirements.txt && \
	python setup.py install && export TOXENV=py27 && python setup.py -q test -q && \
	pip install -U setuptools && nosetests && \
	pip uninstall -y ipython mock pandas flake8 pytest nose ptyprocess && \
	apt-get remove -y git && apt-get -y purge && apt-get -y autoremove
