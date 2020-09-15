FROM ppc64le/python:2.7

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN git clone https://github.com/jsocol/pystatsd && \
	cd pystatsd && python setup.py install

CMD ["/bin/bash"]
