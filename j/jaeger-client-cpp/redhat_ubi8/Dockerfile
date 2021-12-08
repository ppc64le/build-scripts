FROM registry.access.redhat.com/ubi8/ubi:latest

MAINTAINER Abhijit Mane <abhijman@in.ibm.com>

# pre-reqs
RUN dnf update -y \
 && dnf install -y git make cmake redhat-rpm-config gcc.ppc64le gcc-c++.ppc64le

# create test user needed for running tests
RUN useradd appuser

USER appuser

CMD [bash]
