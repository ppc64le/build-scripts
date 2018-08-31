FROM ubuntu:18.04

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN apt-get update && apt-get install -y deltarpm libgdal-dev libproj-dev gdal-bin python-dev git python-setuptools python-pip && \
	git clone https://github.com/matplotlib/cycler && \
	cd cycler && \
	python setup.py install && pip install pytest && python setup.py test

CMD ["/bin/bash"]
