########################################################################################################################
# Dockerfile to run a snowdrop Container
# Docker build command:
# docker build -t snowdrop .
# Docker run command:
# docker run -it --name sd snowdrop
########################################################################################################################

FROM registry.access.redhat.com/ubi8/ubi:latest

LABEL name="rhosp13/snowdrop" \
      maintainer="amol.patil2@ibm.com" \
      vendor="VendorX" \
      version="0.15.0" \
      release="1" \
      summary="Red Hat OpenStack Platform 13.0 snowdrop" \
      description="Red Hat OpenStack Platform 13.0 snowdrop"

ENV GOROOT "/go"
ENV PATH $PATH:$GOROOT/bin

RUN yum update -y && yum install -y git vim wget curl gcc gcc-c++ \
 && wget https://dl.google.com/go/go1.12.7.linux-ppc64le.tar.gz \
 && gunzip go1.12.7.linux-ppc64le.tar.gz && tar -xvf go1.12.7.linux-ppc64le.tar \ 
 && mkdir -p /go/src/github.com/snowdrop && cd /go/src/github.com/snowdrop \
 && git clone https://github.com/snowdrop/snowdrop-cloud-devex.git && cd snowdrop-cloud-devex \
 && go get "github.com/snowdrop/spring-boot-cloud-devex/cmd" \
 && go get "github.com/snowdrop/spring-boot-cloud-devex/pkg/common/logger" \
 && go build && go test \
 && ln -s `pwd`/snowdrop-cloud-devex /usr/bin/sd

RUN groupadd snowdrop && useradd -r -g snowdrop snowdrop -m -d /home/snowdrop 

USER snowdrop 

WORKDIR /home/snowdrop 

CMD ["/bin/bash"]

