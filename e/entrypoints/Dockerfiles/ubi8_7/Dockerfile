FROM registry.access.redhat.com/ubi8:8.7

MAINTAINER "Stuti Wali <Stuti.Wali@ibm.com>"

ARG PACKAGE_VERSION=0.4

ENV SOURCE_DIR=$PWD
ENV PATH=/usr/local/bin:$PATH

RUN yum install -y python39 git gcc-c++ python39-devel.ppc64le python3-setuptools
RUN pip3 install --upgrade setuptools virtualenv mock ipython_genutils pytest traitlets flit
RUN dnf install -qy http://mirror.nodesdirect.com/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-gpg-keys-8-6.el8.noarch.rpm && \
    dnf install -qy http://mirror.nodesdirect.com/centos/8-stream/BaseOS/ppc64le/os/Packages/centos-stream-repos-8-6.el8.noarch.rpm && \
    dnf config-manager --enable powertools && \
    dnf install -qy epel-release


ENV TOXENV=py39

RUN virtualenv -p python3 --system-site-packages env2 && \
    /bin/bash -c "source env2/bin/activate"
    
ENV PATH=$PATH:/usr/local/bin/

RUN git clone https://github.com/takluyver/entrypoints && \
    cd entrypoints && \
    git checkout $PACKAGE_VERSION && \
    pip3 install setuptools wheel && \
    pip3 install configparser && \
    pip3 install -U entrypoints && \
    pip3 install . pytest

CMD ["bash"]

