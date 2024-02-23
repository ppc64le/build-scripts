FROM registry.access.redhat.com/ubi8/ubi:8.7

MAINTAINER "Abhishek Dwivedi <Abhishek.Dwivedi6@ibm.com>"

RUN yum install -y git gcc make python38 &&\
        git clone https://github.com/snowballstem/snowball.git && \
        cd snowball && \
        make

CMD ["/bin/bash"]