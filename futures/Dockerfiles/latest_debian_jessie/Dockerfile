FROM ppc64le/python:2.7

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN apt-get update -y && \
	apt-get install -y build-essential && \
	git clone https://github.com/agronholm/pythonfutures && \
	cd pythonfutures && \
	python setup.py install && python test_futures.py && \
	apt-get purge -y build-essential && \
	apt-get -y autoremove

CMD ["/bin/bash"]
