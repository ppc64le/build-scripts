#Docker build command:
#docker build -t cadvisor .
#Docker run command:
#docker run -p <port>:8080 -d -t cadvisor

FROM ppc64le/golang:1.8

# The author
MAINTAINER "Priya Seth <sethp@us.ibm.com>"

# Set env variables for gccgo
ENV GOPATH "/cadvisor"
ENV PATH $PATH:$GOPATH/bin
ENV CADVISOR_VERSION v0.27.1

# Install godep tool, clone source and build it
RUN go get github.com/tools/godep \
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
