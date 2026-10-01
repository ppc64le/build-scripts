FROM ppc64le/python:2.7

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN git clone https://github.com/zopefoundation/Btrees && \
	cd Btrees && \
	pip install -U pip setuptools && pip install -U persistent && pip install -e . && python setup.py -q test -q

CMD ["/bin/bash"]
