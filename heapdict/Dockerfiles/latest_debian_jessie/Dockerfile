#Dockerfile for building "heapdict" on Ubuntu16.04
FROM ppc64le/python:2.7
MAINTAINER Archa Bhandare <barcha@us.ibm.com>

RUN apt-get update \
        && git clone https://github.com/DanielStutzbach/heapdict \
        && cd heapdict/ && python setup.py install && python test_heap.py \
		&& cd ../ && apt-get -y autoremove && rm -rf /heapdict/

CMD ["python", "/bin/bash"]

