FROM registry.access.redhat.com/ubi8/ubi:8.7

MAINTAINER "Mohit Pawar <Mohit.Pawar@ibm.com>"

ENV HOME_DIR=${PWD}

RUN yum update -y && \
	yum install -y git gcc gcc-c++ yum-utils make automake autoconf libtool gdb* binutils rpm-build gettext wget && \
	yum install -y libffi-devel libpq-devel -y && \
	yum install -y python3.11 python3.11-devel python3.11-setuptools && \
	python3 -m ensurepip --upgrade && \
	python3 -m pip install tox --ignore-installed && \
	git clone https://github.com/zopefoundation/BTrees.git && \
	cd BTrees && \
	python3 setup.py build
	
CMD ["/bin/bash"]

