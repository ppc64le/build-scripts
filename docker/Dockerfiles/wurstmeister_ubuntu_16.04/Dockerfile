#This Dockerfile has been adapted for ppc64le 
#from the original work here 
# https://github.com/wurstmeister/docker-base

FROM ubuntu:xenial
MAINTAINER "Priya Seth <sethp@us.ibm.com>"
RUN apt-get update; apt-get install -y unzip openjdk-8-jre-headless wget supervisor docker.io openssh-server
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-ppc64el/
RUN echo 'root:wurstmeister' | chpasswd
RUN mkdir /var/run/sshd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

EXPOSE 22
