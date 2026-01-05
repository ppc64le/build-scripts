FROM registry.access.redhat.com/ubi9/ubi:9.3

MAINTAINER "Mohit Pawar <Mohit.Pawar@ibm.com>"

ENV HOME_DIR=${PWD}
ARG PACKAGE_VERSION=v2.1.0

RUN yum update -y && \
	yum install -y git python3 python3-devel.ppc64le gcc gcc-c++ make wget sudo && \
	yum install -y python3-numpy && \
	python3 -m pip install ez_setup nose pytest --ignore-installed && \
	pip3 install pytest tox && \
	PATH=$PATH:/usr/local/bin/ && \
	git clone https://github.com/holoviz/param.git && \
	cd param && \
	git checkout $PACKAGE_VERSION && \
	python3 -m pip install build

CMD ["/bin/bash"]
