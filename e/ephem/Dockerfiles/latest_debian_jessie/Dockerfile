FROM ppc64le/python:2.7

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN apt-get update && apt-get install -y build-essential && \
	git clone https://github.com/brandon-rhodes/pyephem && \
	cd pyephem && \
	python setup.py install && virtualenv -p python2 --system-site-packages env2 && \
	/bin/bash -c "source env2/bin/activate"  && python setup.py build_ext -i && \
	python -m unittest discover ephem && \
	apt-get purge -y build-essential && \
	apt-get -y autoremove

CMD ["/bin/bash"]
