FROM golang:1.10
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

RUN apt-get update -y \
	&& mkdir -p $GOPATH/src/github.com/twinj \
	&& cd $GOPATH/src/github.com/twinj \
	&& go get github.com/stretchr/testify \
	&& go get github.com/stretchr/testify/assert \
	&& git clone --branch=v1.0.0 https://github.com/twinj/uuid.git \
	&& cd uuid \
	&& go get -t -v ./... \
	&& go test -v -short 

CMD ["/bin/bash"]

