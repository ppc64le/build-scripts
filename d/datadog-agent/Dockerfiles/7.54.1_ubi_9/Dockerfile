FROM registry.access.redhat.com/ubi9/ubi:9.3

MAINTAINER "Ramnath Nayak <Ramnath Nayak@ibm.com>"

ARG PACKAGE_VERSION=7.54.1
ARG PATCH=https://raw.githubusercontent.com/ramnathnayak-ibm/build-scripts/datadog-agent/d/datadog-agent/datadog-agent_7.54.1.patch

ENV GOROOT=${GOROOT:-"/usr/local/go"}
ENV GOPATH=${GOPATH:-$HOME/go}
ENV PATH=$PATH:$GOROOT/bin:1.22.0/bin:/usr/local/bin

RUN yum install -y wget git python3 python3-devel openssl openssl-devel make gcc gcc-c++ diffutils cmake patch

# Install all dependencies
RUN wget https://golang.org/dl/go1.22.0.linux-ppc64le.tar.gz && \
	tar -C /usr/local -xvzf go1.22.0.linux-ppc64le.tar.gz && \
	rm -rf go1.22.0.linux-ppc64le.tar.gz && \
	python3 -m pip install --upgrade pip

RUN git clone https://github.com/DataDog/datadog-agent && \
	cd datadog-agent && \
	git checkout $PACKAGE_VERSION && \
	wget $PATCH &&\
	git apply --ignore-whitespace datadog-agent_7.54.1.patch &&\
	python3 -m pip install codecov -r requirements.txt || true &&\
	export PATH=$PATH:/usr/local/bin &&\
	invoke -e install-tools &&\
	invoke -e rtloader.make && invoke -e rtloader.install &&\
	invoke agent.build --build-exclude=systemd
	
CMD ["/bin/bash"]
