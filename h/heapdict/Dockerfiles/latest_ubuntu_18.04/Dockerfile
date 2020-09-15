#Dockerfile for building "heapdict" on Ubuntu16.04

FROM ubuntu:18.04

MAINTAINER Priya Seth <sethp@us.ibm.com>

RUN apt-get update \
	&& apt-get install -y python-dev python-pip python-setuptools git \
	&& pip install pytest \
        && git clone https://github.com/DanielStutzbach/heapdict \
        && cd heapdict/ && python setup.py install && python test_heap.py \
	&& cd ../ && apt-get -y purge git && apt-get -y autoremove && rm -rf /heapdict/

CMD ["python", "/bin/bash"]

