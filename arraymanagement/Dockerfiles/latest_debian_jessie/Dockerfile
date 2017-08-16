FROM ppc64le/python:2.7

MAINTAINER Snehlata Mohite <smohite@us.ibm.com>

RUN apt-get update && apt-get install -y libhdf5-dev && \
    pip install --upgrade pip && \
	pip install numpy numexpr cython nose pytest tables sqlalchemy pandas && \
    cd $HOME/ && git clone https://github.com/ContinuumIO/ArrayManagement.git && \
	cd $HOME/ArrayManagement/ && python setup.py build && python setup.py install && \ 
	cd $HOME/ && rm -rf ArrayManagement && apt-get purge -y libhdf5-dev && apt-get -y autoremove
	
CMD ["python", "/bin/bash"]

