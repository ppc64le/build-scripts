FROM ubuntu:18.04

## Author of the new image
MAINTAINER Priya Seth <sethp@us.ibm.com>

ENV DEBIAN_FRONTEND noninteractive
ENV TOXENV py27

## Update source, Install dependencies, >Clone repo
RUN apt-get -y update && \
	apt-get install -y build-essential software-properties-common \
		git python-setuptools python-dev locales locales-all \
		python-pip python-setuptools && \
	pip install virtualenv && \
	git clone https://github.com/Pylons/pyramid_mako && \
	cd pyramid_mako/ && \
	python setup.py install && \
	virtualenv -p python2 --system-site-packages env2 && \
	/bin/bash -c "source env2/bin/activate" && \
	pip install tox && tox && \
	apt-get purge -y git && \
	apt-get -y autoremove
