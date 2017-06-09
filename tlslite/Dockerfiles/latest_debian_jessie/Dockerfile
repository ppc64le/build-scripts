FROM ppc64le/python:2.7

MAINTAINER Yugandha Deshpande <yugandha@us.ibm.com>

RUN apt-get update -y \
	&& apt-get install -y build-essential git openssl m2crypto \
        && pip install -U nose \
        && git clone https://github.com/trevp/tlslite \
	&& cd tlslite && python setup.py install && nosetests -v	

WORKDIR /tlslite
CMD ["/bin/bash"]	

