FROM ppc64le/python:2.7

MAINTAINER "Priya Seth<sethp@us.ibm.com>"

RUN apt-get update -y && \
	apt-get install -y build-essential && \
	easy_install pip && pip install --upgrade setuptools virtualenv mock ipython_genutils pytest traitlets && \
	git clone https://github.com/jpvanhal/inflection && \
	cd inflection && \
	pip install -r requirements.txt && flake8 .  && isort --recursive --diff . && \
	isort --recursive --check-only . && py.test && \
	apt-get purge -y build-essential && \
	apt-get -y autoremove

CMD ["/bin/bash"]
