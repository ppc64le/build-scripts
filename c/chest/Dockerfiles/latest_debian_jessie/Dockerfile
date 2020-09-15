FROM ppc64le/python:2.7

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN easy_install pip && pip install coverage pep8 nose numpy && \
	git clone https://github.com/blaze/chest && \
	cd chest && \
	pip install -r requirements.txt && python setup.py install && nosetests

CMD ["/bin/bash"]
