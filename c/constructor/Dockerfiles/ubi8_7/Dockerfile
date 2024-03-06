FROM registry.access.redhat.com/ubi8:8.7

MAINTAINER "Stuti Wali <Stuti.Wali@ibm.com>"

ENV SOURCE_DIR=$PWD
ENV PATH=/usr/local/bin:$PATH

RUN yum install -y gcc gcc-c++ make cmake git wget  autoconf automake libtool pkgconf-pkg-config info python38-devel python38-setuptools curl gzip tar bzip2 zip unzip xz zlib-devel yum-utils fontconfig fontconfig-devel openssl-devel  fontconfig fontconfig-devel ncurses-compat-libs ncurses-devel python3-setuptools

RUN cd $SOURCE_DIR && \
    git clone https://github.com/conda/constructor && \
    cd constructor && \
    git checkout 3.6.0 && \
    cd ..

RUN wget https://repo.anaconda.com/miniconda/Miniconda3-py38_4.9.2-Linux-ppc64le.sh -O miniconda.sh && \
    bash miniconda.sh -b -p $HOME/miniconda

ENV PATH="/root/miniconda/bin:$PATH"

RUN /root/miniconda/condabin/conda config --add channels conda-forge && \
    cd $SOURCE_DIR && \
    conda env create -n constructor-dev -f constructor/dev/environment.yml && \
    conda init bash && \
    eval "$(conda shell.bash hook)" && \
    conda activate constructor-dev && \
    pip install pytest pytest-cov coverage jinja2 && \
    wget https://rpmfind.net/linux/opensuse/distribution/leap/15.4/repo/oss/ppc64le/python3-ruamel.yaml.clib-0.2.0-1.1.ppc64le.rpm && \
    rpm -i python3-ruamel.yaml.clib-0.2.0-1.1.ppc64le.rpm

ENV PATH="$HOME/miniconda/bin:$PATH"
ENV LD_LIBRARY_PATH=/usr/lib64
ENV PATH=$LD_LIBRARY_PATH:$PATH

RUN cd $SOURCE_DIR && \
    cd constructor && \
    python3 setup.py build && \
    python3 setup.py install

CMD ["bash"]
