FROM registry.access.redhat.com/rhel7:latest

MAINTAINER Abhijit Mane <abhijman@in.ibm.com>

# Important
# For rhel7 image, appropriate RHEL-7 repo needs to be setup to proceed.
# Ex: If using rhel subscription, then register & enable epel repos
#  subscription-manager register --username 'user' --password 'password' --auto-attach
#  subscription-manager repos --enable "rhel-*-optional-rpms" --enable "rhel-*-extras-rpms"

RUN yum update -y

## setup epel repo on rhel-7.9
RUN yum install wget -y \
 && wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm \
 && yum install epel-release-latest-7.noarch.rpm -y

RUN yum install -y git make cmake gcc-c++ java-1.8.0-openjdk java-1.8.0-openjdk-devel java-1.8.0-openjdk-headless \
    zlib zlib-devel bzip2 bzip2-devel libzstd libzstd-devel snappy snappy-devel lz4 gflags

CMD [bash]
