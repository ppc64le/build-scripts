FROM ubuntu:18.04

RUN apt-get update && apt-get install -y  \
        libpq-dev \
	python-dev \
        python-ldap \
        python-ldappool \
        python-memcache \
        memcached \
        build-essential \
        libsasl2-dev \
        libldap2-dev \
        libssl-dev \
        libffi-dev \
        python-setuptools \
        libxml2-dev \
        libxslt1-dev \
        git \
	python-pip \
	&& git clone https://github.com/wbolster/aaargh \
	&& cd aaargh \
	&& pip install -r test-requirements.txt \
	&& py.test \
	&& apt-get purge -y build-essential git libsasl2-dev libldap2-dev \
		libssl-dev libffi-dev libxml2-dev libxslt1-dev \
	&& apt-get -y autoremove 

CMD ["/bin/bash"]
