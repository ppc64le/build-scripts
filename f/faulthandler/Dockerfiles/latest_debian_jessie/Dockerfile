FROM ppc64le/python:2.7

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN apt-get update && apt-get install -y build-essential && \
	easy_install pip && \
	pip install --upgrade setuptools virtualenv mock ipython_genutils \
		pytest traitlets && \
	git clone https://github.com/haypo/faulthandler && \
	cd faulthandler/ && \
	python setup.py install && export TOXENV=py27 && \
	virtualenv -p python2 --system-site-packages env2 && \
	/bin/bash -c "source env2/bin/activate" && \
	pip install tox && tox

CMD ["/bin/bash"]
