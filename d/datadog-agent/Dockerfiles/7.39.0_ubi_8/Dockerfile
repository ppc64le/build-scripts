FROM registry.access.redhat.com/ubi8/ubi:latest 

ARG PACKAGE_VERSION=7.39.0
ARG PATCH=https://raw.githubusercontent.com/vishakadesai/build-scripts/dda/d/datadog-agent/datadog-agent_7.39.0.patch

# Install all dependencies
RUN yum install -y wget git python38 python38-devel openssl openssl-devel make gcc gcc-c++ diffutils cmake

# Install go
RUN export WORKDIR=`pwd` && \
	wget https://go.dev/dl/go1.17.6.linux-ppc64le.tar.gz && \
	tar -C /bin -xf go1.17.6.linux-ppc64le.tar.gz && \
	mkdir -p $WORKDIR/go/src $WORKDIR/go/bin $WORKDIR/go/pkg

ENV PATH=$PATH:/bin/go/bin
ENV GOPATH=$WORKDIR/go
ENV PATH=$PATH:$WORKDIR/go/bin
	
RUN python3 -m pip install --upgrade pip 
	
# Clone datadog-agent and build 
RUN cd $GOPATH/src && \
	git clone https://github.com/DataDog/datadog-agent.git && \
	cd datadog-agent && git checkout $PACKAGE_VERSION && \
	wget $PATCH && \
	git apply ${PATCH##*/} && \
	python3 -m pip install codecov -r requirements.txt && \
	invoke -e install-tools && \
	invoke agent.build --build-exclude=systemd && \
	invoke -e rtloader.make && invoke -e rtloader.install && \
	invoke test --skip-linters --build-exclude=systemd

ENV PATH=$PATH:$GOPATH/src/datadog-agent/bin/agent