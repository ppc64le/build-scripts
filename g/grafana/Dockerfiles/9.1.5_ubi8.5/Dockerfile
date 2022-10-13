FROM registry.access.redhat.com/ubi8/ubi:8.4

ARG GRAFANA_VERSION=v9.1.6

ENV GOPATH=/grafana
ENV PATH=$PATH:/usr/local/go/bin

#Install Go and Path
RUN yum -y update && \
	yum -y install wget git gcc gcc-c++ && \
	wget https://golang.org/dl/go1.17.1.linux-ppc64le.tar.gz && \
	tar -C /usr/local -xzf go1.17.1.linux-ppc64le.tar.gz 
	
RUN yum install -y python2 make && \
	wget https://nodejs.org/dist/latest-v14.x/node-v18.9.0.tar.gz && \
	tar -xzf node-v18.9.0.tar.gz && cd node-v18.9.0 && ./configure && make && make install 
	
RUN cd / && mkdir grafana && cd grafana && \
	git clone https://github.com/grafana/grafana.git && cd grafana && \
	git checkout $GRAFANA_VERSION && \
	go run build.go setup && \
	go run build.go build && \
	npm install -g yarn && \
	yarn install --immutable && \
	npm run build && \
	yum remove wget git make gcc gcc-c++ -y

EXPOSE 3000

WORKDIR /grafana/grafana
CMD ["./bin/linux-ppc64le/grafana-server"]

