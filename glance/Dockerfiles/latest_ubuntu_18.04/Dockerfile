FROM ubuntu:18.04

MAINTAINER Amit Ghatwal <ghatwala@us.ibm.com>

RUN apt-get update && \
        apt-get install -y python git python-pip  python-dev libpq-dev python-ldappool \
        python-memcache memcached build-essential libsasl2-dev libldap2-dev libssl-dev \
        libffi-dev gcc python-setuptools libssl-dev libxml2-dev libxslt1-dev

RUN git clone https://github.com/openstack/glance.git && cd glance && \
        #pip install --upgrade pip && hash -d pip && \
        pip install -r requirements.txt && \
        python setup.py install && \
        pip install tox

CMD ["/bin/bash"]
