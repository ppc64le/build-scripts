FROM ppc64le/python:2.7

MAINTAINER Snehlata Mohite <smohite@us.ibm.com>

RUN apt-get update && apt-get install -y --no-install-recommends apt-utils libblas-dev liblapack-dev libatlas-base-dev gfortran && \
    pip install --upgrade pip && \
    cd $HOME/ && git clone https://github.com/Lasagne/Lasagne.git && \
	cd $HOME/Lasagne/ && pip install -r requirements-dev.txt  && pip install -r requirements.txt && \
	cd $HOME/Lasagne/ && python setup.py build && python setup.py install && py.test --runslow --cov-config=.coveragerc-nogpu && \
	cd $HOME/ && rm -rf Lasagne && apt-get purge -y libblas-dev liblapack-dev libatlas-base-dev gfortran apt-utils  && apt-get -y autoremove
	
CMD ["python", "/bin/bash"]
