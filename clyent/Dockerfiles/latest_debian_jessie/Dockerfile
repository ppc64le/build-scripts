FROM python:2.7.15-stretch

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN pip install mock && \ 
        git clone https://github.com/Anaconda-Platform/clyent && \
	cd clyent && \
	python setup.py install && python setup.py -q test -q

CMD ["/bin/bash"]
