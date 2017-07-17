FROM ppc64le/python:2.7

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN git clone https://github.com/Anaconda-Platform/clyent && \
	cd clyent && \
	python setup.py install && python setup.py -q test -q

CMD ["/bin/bash"]
