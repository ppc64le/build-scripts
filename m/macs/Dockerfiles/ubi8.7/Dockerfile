FROM registry.access.redhat.com/ubi8/ubi:8.7

MAINTAINER "Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>"

ENV HOME_DIR=${PWD}

ARG PACKAGE_VERSION=v3.0.0

RUN yum update -y && \
        yum install -y wget gcc git gcc-c++ gcc-gfortran.ppc64le openblas.ppc64le zlib-devel &&\
	      wget https://repo.anaconda.com/miniconda/Miniconda3-py39_4.9.2-Linux-ppc64le.sh -O miniconda.sh &&\
	      bash miniconda.sh -b -p $HOME/miniconda &&\
	      export PATH="$HOME/miniconda/bin:$PATH" &&\
	      python3 -m pip install -U pip && \
        cd $HOME_DIR && \
        git clone https://github.com/macs3-project/MACS/ && \
        cd MACS && \
        git checkout $PACKAGE_VERSION && \
	      git submodule update --init --recursive &&\
	      conda install openblas cython numpy scipy -y &&\
	      python3 -m pip install --upgrade --progress-bar off pytest &&\
        python3 -m pip install --upgrade-strategy only-if-needed --no-build-isolation --progress-bar off .

CMD ["/bin/bash"]