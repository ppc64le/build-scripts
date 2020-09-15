FROM ubuntu:18.04

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN apt-get update -y && \
	apt-get install -y build-essential python-dev python-pip python-setuptools git && \
	pip install pytest && \
	git clone https://github.com/agronholm/pythonfutures && \
	cd pythonfutures && \
	python setup.py install && python test_futures.py && \
	apt-get purge -y build-essential git && \
	apt-get -y autoremove

CMD ["/bin/bash"]
