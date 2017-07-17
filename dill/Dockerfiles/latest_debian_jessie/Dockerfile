FROM ppc64le/python:2.7

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN apt-get update && apt-get install -y deltarpm libgdal-dev libproj-dev gdal-bin && \
	git clone https://github.com/uqfoundation/dill/ && \
	cd dill && \
	python setup.py install && python setup.py test 

CMD ["/bin/bash"]
