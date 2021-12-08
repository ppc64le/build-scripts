FROM registry.access.redhat.com/ubi8/ubi:latest
MAINTAINER Krishna Harsha Voora <krishvoor@in.ibm.com>

RUN dnf update -y \
  && dnf install git patch gcc gcc-c++ curl wget perl-App-cpanminus diffutils -y \
  && dnf install zlib zlib-devel dos2unix -y \
  && dnf install https://rpmfind.net/linux/centos/8.3.2011/AppStream/ppc64le/os/Packages/mercurial-4.8.2-1.module_el8.0.0+40+715dddeb.ppc64le.rpm -y

CMD [bash]
