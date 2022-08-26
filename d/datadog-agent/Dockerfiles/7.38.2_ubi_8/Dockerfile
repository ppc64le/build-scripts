FROM registry.access.redhat.com/ubi8/ubi:latest

ARG PACKAGE_VERSION=7.38.2

WORKDIR /root

# Install required dependencies
RUN yum install -y wget git python38 python38-devel openssl openssl-devel make gcc gcc-c++ diffutils cmake
	
# Install go version 1.17
RUN wget https://go.dev/dl/go1.17.6.linux-ppc64le.tar.gz && \
    tar -C /bin -xf go1.17.6.linux-ppc64le.tar.gz && \
    mkdir -p /root/go/src /root/go/bin /root/go/pkg && \
    rm -rf go1.17.6.linux-ppc64le.tar.gz 

ENV PATH=$PATH:/bin/go/bin
ENV GOPATH=/root/go
ENV PATH=$PATH:$GOPATH/bin

# Upgrade pip
RUN python3 -m pip install --upgrade pip 
	
# Clone datadog-agent 
RUN git clone https://github.com/DataDog/datadog-agent.git $GOPATH/src/github.com/DataDog/datadog-agent && \
    cd $GOPATH/src/github.com/DataDog/datadog-agent && \
    git checkout $PACKAGE_VERSION

# Fetch and apply patch
RUN wget https://raw.githubusercontent.com/vishakadesai/build-scripts/master/d/datadog-agent/datadog-agent_7.38.2.patch && \
    git apply --ignore-whitespace datadog-agent_7.38.2.patch

# Build and install dependencies
RUN python3 -m pip install codecov -r requirements.txt && \
    invoke -e install-tools && \
    invoke agent.build --build-exclude=systemd

# To build rtloader
RUN invoke -e rtloader.make && invoke -e rtloader.install

# To test
RUN invoke test --skip-linters --build-exclude=systemd