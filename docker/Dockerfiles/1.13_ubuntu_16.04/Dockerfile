FROM ppc64le/ubuntu:16.04
MAINTAINER Yugandha Deshpande <yugandha@us.ibm.com>

RUN echo deb http://ftp.unicamp.br/pub/ppc64el/ubuntu/16_04/docker-1.13.1-ppc64el/ xenial  main > /etc/apt/sources.list.d/xenial-docker.list
RUN apt-get update
RUN apt-get install docker-engine -y --allow-unauthenticated
EXPOSE 2375
CMD ["sh"]
