FROM ubuntu:16.04
MAINTAINER Vibhuti.Sawant@ibm.com
RUN apt-get update && apt-get install -y curl wget tar bzip2 && \
    curl https://repo.continuum.io/miniconda/Miniconda3-4.3.14-Linux-ppc64le.sh -o /tmp/miniconda.sh && \
    /bin/bash /tmp/miniconda.sh -b -p /opt/conda && \
    rm /tmp/miniconda.sh

ENV PATH /opt/conda/bin:$PATH
# Dumb init
RUN wget -O /usr/local/bin/dumb-init https://github.com/Yelp/dumb-init/releases/download/v1.2.1/dumb-init_1.2.1_ppc64el
RUN chmod +x /usr/local/bin/dumb-init

RUN conda update conda && conda install "conda=4.4.8"
RUN conda install -c conda-forge --yes \
    python-blosc \
    cytoolz \
    dask==0.18.1  \
    distributed==1.22.0 \
    nomkl \
    numpy \
    pandas==0.22.0 \
    && conda clean -tipsy

COPY prepare.sh /usr/bin/prepare.sh
RUN chmod +x /usr/bin/prepare.sh

RUN mkdir /opt/app

ENTRYPOINT ["/usr/local/bin/dumb-init", "/usr/bin/prepare.sh"]
