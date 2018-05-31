FROM python:3
MAINTAINER "Jay Joshi <joshija@us.ibm.com>"
   
RUN apt-get update -y \
   && git clone https://github.com/k-bx/python-semver \
   && cd python-semver/ \
   && python setup.py install \
   && export TOXENV=py27 \
   && python setup.py test

CMD ["/bin/bash"]
