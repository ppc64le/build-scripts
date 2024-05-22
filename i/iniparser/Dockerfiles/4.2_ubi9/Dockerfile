FROM registry.access.redhat.com/ubi9/ubi:9.3

ARG PACKAGE_VERSION=v4.2

RUN yum install gcc gcc-c++ make git wget cmake -y

RUN git clone https://github.com/ndevilla/iniparser && \
    cd iniparser && \
    git checkout $PACKAGE_VERSION && \
    make

CMD ["/bin/bash"]
