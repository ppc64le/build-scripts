FROM registry.access.redhat.com/rhel7:latest

MAINTAINER Abhijit Mane <abhijman@in.ibm.com>

# Important
# For rhel7 image, appropriate RHEL-7 repo needs to be setup to proceed.
# Ex: If using rhel subscription, then register & enable epel repos
#  subscription-manager register --username 'user' --password 'password' --auto-attach
#  subscription-manager repos --enable "rhel-*-optional-rpms" --enable "rhel-*-extras-rpms"

RUN yum update -y \
 && yum install gcc git wget \
    java-1.8.0-openjdk.ppc64le java-1.8.0-openjdk-devel.ppc64le java-1.8.0-openjdk-headless.ppc64le -y

# Install ant
RUN wget https://apachemirror.wuchna.com//ant/binaries/apache-ant-1.10.10-bin.tar.gz \
 && tar -zxf apache-ant-1.10.10-bin.tar.gz \
 && export PATH=$PATH:$PWD/apache-ant-1.10.10/bin

CMD [bash]
