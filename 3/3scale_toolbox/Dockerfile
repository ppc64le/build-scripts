FROM registry.access.redhat.com/ubi8/ubi:latest

MAINTAINER Abhijit Mane <abhijman@in.ibm.com>

# pre-reqs
RUN yum install -y git make cmake gem ruby redhat-rpm-config ruby-devel zlib.ppc64le \
                   zlib-devel.ppc64le gcc.ppc64le gcc-c++.ppc64le \
 && gem install bundler \
 && gem install racc

CMD [bash]
