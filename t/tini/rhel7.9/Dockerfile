FROM registry.access.redhat.com/rhel7:latest

MAINTAINER Abhijit Mane <abhijman@in.ibm.com>

# Important
# For rhel7 image, appropriate RHEL-7 repo needs to be setup to proceed.
# Ex: If using rhel subscription, then register & enable epel repos
#  subscription-manager register --username 'user' --password 'password' --auto-attach
#  subscription-manager repos --enable "rhel-*-optional-rpms" --enable "rhel-*-extras-rpms"

RUN yum update -y
RUN yum install -y git gcc cmake make glibc-static

CMD [bash]
