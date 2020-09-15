FROM golang:1.10-stretch

RUN apt-get update && \
        apt-get install -y cpp libc6-dev autoconf automake bison flex libtool \
                ecj make texinfo libgmp10 libmpfr4 libmpfr-dev libmpc3 libmpc-dev zip \
                unzip antlr subversion zlib1g zlib1g-dev build-essential git && \
        git clone https://github.com/go-inf/inf.git && \
        cd inf && mkdir go && go get gopkg.in/inf.v0 && go test -v ./... && \
        apt-get purge -y cpp autoconf automake bison flex libtool ecj make texinfo  libmpfr-dev \
                libmpc-dev zip unzip antlr subversion zlib1g-dev build-essential git  && \
        apt-get autoremove -y

WORKDIR /inf
ENTRYPOINT ["/bin/bash"]
