FROM ppc64le/python:2.7

MAINTAINER "Priya Seth<sethp@us.ibm.com>"

RUN apt-get update -y && \
	apt-get install -y build-essential && \
	git clone https://github.com/takluyver/entrypoints && \
	cd entrypoints/ && \
	pip install configparser && pip install -U entrypoints &&  pip install -U pytest && \
	python tests/test_entrypoints.py && py.test && \
	apt-get purge -y build-essential && \
	apt-get -y autoremove

CMD ["/bin/bash"]
