#Dockerfile for building "et_xmlfile" on Ubuntu16.04
FROM ppc64le/python:2.7
MAINTAINER Archa Bhandare <barcha@us.ibm.com>

RUN apt-get update \
    && apt-get install -y mercurial \
    && hg clone https://bitbucket.org/openpyxl/et_xmlfile/src et_xmlfile \
    && cd et_xmlfile/ && python setup.py install && python setup.py test \
    && cd ../ && apt-get remove -y mercurial && apt-get -y autoremove && rm -rf et_xmlfile/

CMD ["python", "/bin/bash"]

