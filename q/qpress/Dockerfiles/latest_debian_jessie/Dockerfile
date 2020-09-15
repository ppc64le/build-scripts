FROM ppc64le/python:2.7

MAINTAINER Amit Ghatwal <ghatwala@us.ibm.com>

RUN apt-get update && \
	apt-get install -y -y wget unzip make g++ && \
	wget http://www.quicklz.com/qpress-11-source.zip && unzip qpress-11-source.zip -d qpress && \
        sed -i '1s/^/#include <unistd.h>\n/' qpress/qpress.cpp && \
	cd qpress && make
	
CMD ["qpress", "/bin/bash"] 
