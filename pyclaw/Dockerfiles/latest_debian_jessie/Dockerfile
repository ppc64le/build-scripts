#Dockerfile for building "pyclaw"
FROM ppc64le/python:2.7
MAINTAINER Archa Bhandare <barcha@us.ibm.com>

ENV DEBIAN_FRONTEND noninteractive
ENV TEST_PACKAGE pyclaw
RUN apt-get update -qq \
        && apt-get install -y -qq gfortran liblapack-pic pv liblapack-dev mpich python-mpi4py python-mpi4py-doc hdf5-helpers hdf5-tools h5utils \
        && wget http://repo.continuum.io/miniconda/Miniconda2-4.3.14-Linux-ppc64le.sh -O miniconda.sh \
        && bash miniconda.sh -b -p /root/miniconda && export PATH="$HOME/miniconda/bin:$PATH" \
        && hash -r && conda config --set always_yes yes --set changeps1 no --set show_channel_urls yes && conda update -q conda \
        && conda install matplotlib nose coverage && pip install petsc4py spicy python-coveralls && python -c "import scipy; print(scipy.__version__)" \
        && git clone --branch=master --depth=100 --quiet git://github.com/clawpack/clawpack && cd clawpack/ \
        && git submodule init && git submodule update clawutil visclaw riemann && python setup.py install \
        && cd pyclaw/src/pyclaw && nosetests --first-pkg-wins --with-doctest --exclude=limiters --exclude=sharpclaw --exclude=fileio --exclude=example --with-coverage --cover-package=clawpack.pyclaw \
        && cd / && pip uninstall -y petsc4py spicy python-coveralls && conda uninstall matplotlib nose coverage \
        && apt-get remove -y pv liblapack-dev mpich python-mpi4py python-mpi4py-doc hdf5-helpers hdf5-tools h5utils -qq gfortran liblapack-pic \
        && apt-get -y autoremove && rm -rf /clawpack/

CMD ["python", "/bin/bash"]


