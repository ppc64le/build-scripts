FROM ppc64le/python:2.7

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN apt-get update && apt-get install -y  libzmq-dev libsodium-dev build-essential && \
	git clone https://github.com/ilanschnell/bsdiff4.git && \
	cd bsdiff4 && \
	python setup.py build_ext --inplace && python -c "import bsdiff4; bsdiff4.test()" && \
	rm -rf build dist && rm -f bsdiff4/*.o bsdiff4/*.so bsdiff4/*.pyc && \
	rm -rf bsdiff4/__pycache__ *.egg-info && \
	apt-get -y purge libzmq-dev libsodium-dev build-essential && \
	apt-get -y autoremove

CMD ["/bin/bash"]
