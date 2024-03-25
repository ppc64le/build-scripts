FROM registry.access.redhat.com/ubi9/ubi:9.3

MAINTAINER "Vinod K <Vinod.K1@ibm.com>"
 
ARG PACKAGE_VERSION=master

RUN yum install -y git python39 python3-pip

RUN git clone https://github.com/defnull/multipart && \
	cd multipart && \
	git checkout $PACKAGE_VERSION && \
	python3 -m pip install --upgrade pip tox
	
CMD ["/bin/bash"]

