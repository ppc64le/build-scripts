FROM registry.access.redhat.com/ubi9/ubi:9.3

MAINTAINER Vipul Ajmera <Vipul.Ajmera@ibm.com>

ARG PACKAGE_VERSION=v3.0.1

RUN yum install -y wget gcc git gcc-c++ gcc-gfortran openblas cmake procps-ng diffutils bc zlib-devel && \
    wget https://repo.anaconda.com/miniconda/Miniconda3-py310_23.10.0-1-Linux-ppc64le.sh -O miniconda.sh && \
    bash miniconda.sh -b -p $HOME/miniconda && \
    export PATH="$HOME/miniconda/bin:$PATH" && \
    python3 -m pip install -U pip && \
    git clone https://github.com/macs3-project/MACS.git && \
    cd MACS && \
    git checkout $PACKAGE_VERSION && \
    git submodule update --init --recursive && \
    conda install openblas cython numpy scipy -y && \
    conda install conda-forge::meson-python -y && \
    conda install conda-forge::pybind11 -y && \
    conda install conda-forge::pythran -y && \
    conda install conda-forge::cython -y && \
    python3 -m pip install --upgrade --progress-bar off pytest && \
    python3 -m pip install --upgrade-strategy only-if-needed --no-build-isolation --progress-bar off . 

CMD ["/bin/bash"]
