FROM ppc64le/python:2.7

MAINTAINER Amit Ghatwal <ghatwala@us.ibm.com>

RUN apt-get update && \
	apt-get install -y --force-yes python-dev libpq-dev python-ldap python-ldappool \
	python-memcache memcached build-essential libsasl2-dev libldap2-dev libssl-dev \
        libffi-dev gcc python-setuptools libssl-dev libxml2-dev libxslt1-dev

RUN git clone https://github.com/openstack/glance.git && cd glance && \
        pip install --upgrade pip && \
	pip install -r requirements.txt && \
	python setup.py install && \
	pip install tox 
	
CMD ["python", "/bin/bash"] 
