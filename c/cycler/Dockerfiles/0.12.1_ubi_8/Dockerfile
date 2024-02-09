FROM registry.access.redhat.com/ubi8/ubi:8.7

MAINTAINER "Mohit Pawar <Mohit.Pawar@ibm.com>"

ENV HOME_DIR=${PWD}

RUN yum update -y && \
	yum install -y git gcc gcc-c++ yum-utils make automake autoconf libtool gdb* binutils rpm-build gettext wget && \
	yum install -y libffi-devel libpq-devel -y && \
	yum install -y python39 python39-devel python39-setuptools && \
	python3 -m ensurepip --upgrade && \ 
	pip3 install tox build pytest && \
	git clone https://github.com/matplotlib/cycler.git && \
	cd cycler && \
	python3 -m build
CMD ["pytest"]
CMD ["/bin/bash"]
