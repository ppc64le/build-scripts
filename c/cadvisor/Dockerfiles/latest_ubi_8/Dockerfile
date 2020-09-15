########################################################################################################################
# Dockerfile to run a Google cAdvisor (Container Advisor) Container
# Docker build command:
# docker build -t cadvisor .
# Docker run command:
# docker run -p <port>:8080 -d -t cadvisor
########################################################################################################################

FROM registry.access.redhat.com/ubi8/ubi:latest

# The author
MAINTAINER "Sarvesh Tamba <sarvesh.tamba@ibm.com>"

# Set env variables for gccgo
ENV GOPATH "/cadvisor"
ENV PATH $PATH:$GOPATH/bin
ENV CADVISOR_VERSION v0.27.1

# Install godep tool, clone source and build it
RUN yum update -y && yum install -y git go \
	&& go get github.com/tools/godep \
	&& mkdir -p $GOPATH/src/github.com/google \
	&& cd $GOPATH/src/github.com/google \
	&& git clone https://github.com/google/cadvisor.git --branch=${CADVISOR_VERSION} \
	&& cd cadvisor \
	&& godep go build .


WORKDIR $GOPATH/src/github.com/google/cadvisor

# Port for cAdvisor
EXPOSE 8080

# Command to execute
CMD ["./cadvisor"]
