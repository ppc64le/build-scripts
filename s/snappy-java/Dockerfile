FROM registry.access.redhat.com/rhel7:latest

MAINTAINER Krishna Harsha Voora <krishvoor@in.ibm.com>

# Important
# For rhel7 image, appropriate RHEL-7 repo needs to be setup to proceed.

ARG USERNAME
ARG PASSWORD

RUN subscription-manager register --username $USERNAME --password $PASSWORD --auto-attach \
  && subscription-manager repos --enable "rhel-*-optional-rpms" --enable "rhel-*-extras-rpms"

RUN yum update -y \
  && yum install make autoconf git java-1.8.0-openjdk.ppc64le java-1.8.0-openjdk-devel.ppc64le java-1.8.0-openjdk-headless.ppc64le -y \
  && yum install wget tar -y \
  && yum install gcc gcc-c++ openssl openssl-devel -y \
  && yum install libstdc++-devel.ppc64le -y \
  && yum install http://mirror.centos.org/altarch/7/os/ppc64le/Packages/libstdc++-static-4.8.5-44.el7.ppc64le.rpm -y


# Install maven

RUN cd /usr/local/bin/ \
  && wget https://www-eu.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz \
  && tar -zxf apache-maven-3.6.3-bin.tar.gz

# Build & Install cmake > 3.1

RUN cd /root/ \
  && git clone https://github.com/Kitware/CMake -v CMake \
  && cd CMake \
  && ./bootstrap \
  && make \
  && make install

ENV PATH=${PATH}:/usr/local/bin/apache-maven-3.6.3/bin/

CMD [bash]
