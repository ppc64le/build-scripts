FROM ppc64le/python:2.7

MAINTAINER Snehlata Mohite <smohite@us.ibm.com>

RUN apt-get update && \
    pip install --upgrade pip && \
	pip install pytest && \
    cd $HOME/ && git clone https://github.com/dstufft/xmlrpc2 && \
	cd $HOME/xmlrpc2/ && python setup.py build && python setup.py install && py.test && \
	cd $HOME/ && rm -rf xmlrpc2
	
CMD ["python", "/bin/bash"]
