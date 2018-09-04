FROM python:3
MAINTAINER "Priya Seth <sethp@us.ibm.com>"

ENV TOXENV py27   
RUN apt-get update -y \
   && git clone https://github.com/k-bx/python-semver \
   && cd python-semver/ \
   && python setup.py install \
   && python setup.py test

CMD ["/bin/bash"]
