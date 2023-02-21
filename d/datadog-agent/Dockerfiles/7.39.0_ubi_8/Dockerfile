FROM registry.access.redhat.com/ubi8/ubi:latest as builder

ARG PACKAGE_VERSION=7.39.0
ARG PATCH=https://raw.githubusercontent.com/ppc64le/build-scripts/master/d/datadog-agent/datadog-agent_7.39.0.patch
ARG GO_VERSION=1.18.5
WORKDIR /root

ENV PATH=$PATH:/bin/go/bin:$WORKDIR/go/bin
ENV GOPATH=$WORKDIR/go

# Install all dependencies
RUN yum install -y wget git python38 python38-devel gcc-c++ cmake && \
        cd $WORKDIR && wget https://go.dev/dl/go${GO_VERSION}.linux-ppc64le.tar.gz && \
        tar -C /bin -xf go${GO_VERSION}linux-ppc64le.tar.gz && \
        mkdir -p $WORKDIR/go/src $WORKDIR/go/bin $WORKDIR/go/pkg && \
        rm -f go${GO_VERSION}.linux-ppc64le.tar.gz && \
        cd $GOPATH/src && \
        git clone https://github.com/DataDog/datadog-agent.git $GOPATH/src/github.com/DataDog/datadog-agent && \
        cd $GOPATH/src/github.com/DataDog/datadog-agent && \
        git checkout $PACKAGE_VERSION && \
        wget $PATCH && \
        git apply ${PATCH##*/} && \
        python3 -m pip install -r requirements.txt && \
        invoke agent.build --build-exclude=systemd && \
        yum remove -y wget git python38 python38-devel cmake gcc-c++ && yum clean all -y && \
        cp -r $GOPATH/src/github.com/DataDog/datadog-agent/cmd/agent $GOPATH/bin && \
        rm -rf $GOPATH/src/github.com

FROM registry.access.redhat.com/ubi8/ubi-minimal
RUN microdnf install -y gcc-c++
COPY --from=builder $GOPATH/bin/agent /usr/bin/
