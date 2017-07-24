FROM ppc64le/ubuntu:16.04
MAINTAINER "Atul Sowani <sowania@us.ibm.com>"

RUN echo "deb http://ports.ubuntu.com/ubuntu-ports/ xenial universe" >> /etc/apt/sources.list
RUN apt-get update -y

RUN apt-get install -y software-properties-common
RUN apt-add-repository -y ppa:ansible/ansible
RUN apt-get update -y
RUN apt-get install -y ansible

RUN echo '[local]\nlocalhost\n' > /etc/ansible/hosts
