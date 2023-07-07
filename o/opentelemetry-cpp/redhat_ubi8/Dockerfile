FROM registry.access.redhat.com/ubi8/ubi:latest
MAINTAINER Krishna H Voora <krishvoor@in.ibm.com>

# pre-reqs
RUN dnf install -y git make cmake gcc gcc-c++ libcurl-devel.ppc64le sudo python3

# Environment
ENV HOME="/root/"

# Build Deps
ADD pre-req.sh /root/

RUN bash -c "/root/pre-req.sh"

CMD [bash]
