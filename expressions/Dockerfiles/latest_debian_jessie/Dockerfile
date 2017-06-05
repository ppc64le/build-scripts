#Dockerfile for building "expressions"
FROM ppc64le/python:2.7
MAINTAINER ajay gautam <agautam@us.ibm.com>
RUN apt-get update -y \

# Installing dependent packages
    && pip install -U pip setuptools

RUN pip install -U pytest typing \

#Clone repo and build
    && git clone https://github.com/DataBrewery/expressions.git \
    && cd expressions && pip install . \
    && python setup.py install && py.test \

    && cd .. && pip uninstall -y typing \
    && apt-get -y autoremove && rm -rf expressions

CMD ["python", "/bin/bash"]
