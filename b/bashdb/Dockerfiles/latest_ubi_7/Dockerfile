########################################################################################################################
# UBI 7 Dockerfile for bashdb 
# Docker build command:
# docker build -t bashdb .
# Docker run command:
# docker run -it bashdb
########################################################################################################################

FROM registry.access.redhat.com/ubi7/ubi:latest

MAINTAINER "Amol Patil <amol.patil2@.ibm.com>"

RUN yum update -y \
&& yum install -y wget tar zip unzip wget autoconf libtool gcc-c++ make

RUN wget https://sourceforge.net/projects/bashdb/files/bashdb/4.4-1.0.1/bashdb-4.4-1.0.1.tar.gz \
&& tar -zxvf bashdb-4.4-1.0.1.tar.gz \
&& rm bashdb-4.4-1.0.1.tar.gz \
&& wdir=`pwd` 

RUN cd $wdir/bashdb-4.4-1.0.1 \
&& ./configure \
&& make \
&& make check \
&& make install 

