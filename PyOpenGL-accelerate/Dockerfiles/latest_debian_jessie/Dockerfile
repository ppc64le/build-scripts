FROM ppc64le/python:2.7

MAINTAINER Snehlata Mohite <smohite@us.ibm.com>

RUN apt-get update && \
    cd $HOME/ && wget https://pypi.python.org/packages/d9/74/293aa8794f2f236186d19e61c5548160bfe159c996ba01ed9144c89ee8ee/PyOpenGL-accelerate-3.1.0.tar.gz#md5=489338a4818fa63ea54ff3de1b48995 && \
    cd $HOME/ && tar -xvf PyOpenGL-accelerate-3.1.0.tar.gz && \
	cd $HOME/PyOpenGL-accelerate-3.1.0/ && python setup.py build && python setup.py install && python setup.py test && \
	cd $HOME/ && rm -rf PyOpenGL-accelerate-3.1.0
	
CMD ["python", "/bin/bash"]

