FROM ubuntu:18.04
MAINTAINER Priya Seth <sethp@us.ibm.com>
RUN apt-get update && apt-get install -y git python python-pip \
# Installing dependent packages
        && pip install setuptools nose pyyaml pytest \

#Clone the git repo and build
        && git clone https://github.com/conda/conda-verify.git && cd conda-verify \

        && python setup.py install && pytest -v \
    && apt-get -y autoremove && cd .. && rm -rf conda-verify

CMD ["pip","show","conda-verify"]
CMD ["python", "/bin/bash"]
