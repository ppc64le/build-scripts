FROM ubuntu:18.04

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN apt-get update && \
	apt-get install -y deltarpm libgdal-dev libproj-dev gdal-bin \
		python-dev python-pip python-setuptools git && \
	pip install pytest tox && \
	git clone https://github.com/uqfoundation/dill/ && \
	cd dill && \
	python setup.py install && tox

CMD ["/bin/bash"]
