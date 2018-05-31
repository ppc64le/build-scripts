FROM ubuntu:16.04 
MAINTAINER "Yugandha deshpande <yugandha@us.ibm.com>"

RUN apt-get update -y \
 && apt-get install -y git gcc make \
 && git clone https://github.com/snowballstem/snowball.git \
 && cd snowball \
 && make \
 && apt-get purge --auto-remove git make -y

ENV PATH $PATH:/snowball
CMD ["snowball"]
