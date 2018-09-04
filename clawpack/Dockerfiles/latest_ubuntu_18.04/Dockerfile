FROM ubuntu:18.04

MAINTAINER Snehlata Mohite <smohite@us.ibm.com>

RUN apt-get update && \
    apt-get install -y --no-install-recommends libopenmpi-dev apt-utils \
		pkg-config libhdf5-dev libpetsc3.4.2-dev petsc-dev libsqlite3-0 liblapack-pic pv \
	        liblapack-dev libfontconfig1 libfreetype6-dev libssl1.0.0 \
		libpng12-0 libjpeg62 libx11-6 libxext6 gcc gfortran \
		python-dev python-pip python-setuptools && \
    pip install --upgrade pip --upgrade setuptools && \
    pip install ez_setup numpy scipy==0.17.1 six nose h5py==2.6.0 pytest petsc petsc4py mpi4py functools32 \
	            subprocess32 pytz cycler tornado pyparsing ez_setup && \
    cd $HOME/ && git clone https://github.com/clawpack/clawpack.git && \
    cd $HOME/clawpack/ && export CLAW=${PWD} && python setup.py git-dev && pip install -e . && nosetests -sv --1st-pkg-wins --exclude=pyclaw && \
    cd $HOME/ && rm -rf clawpack && apt-get purge -y pkg-config libsqlite3-0 libhdf5-dev libpetsc3.4.2-dev petsc-dev libopenmpi-dev liblapack-pic pv \
	               liblapack-dev libfontconfig1 libfreetype6-dev libssl1.0.0 libpng12-0 libjpeg62 libx11-6 libxext6 gcc gfortran && apt-get -y autoremove

CMD ["python", "/bin/bash"]

