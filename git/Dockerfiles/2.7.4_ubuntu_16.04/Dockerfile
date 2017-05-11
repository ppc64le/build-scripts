FROM ppc64le/ubuntu:16.04

MAINTAINER "Priya Seth <sethp@ibm.com>"

#Install an already available version of git
RUN apt-get update\
    && apt-get install -y git

ENTRYPOINT ["/usr/bin/git"]


