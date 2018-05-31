FROM golang:1.9
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

RUN go get github.com/prometheus/collectd_exporter \
	&& cd $GOPATH/src/github.com/prometheus/collectd_exporter \
	&& git checkout v0.4.0 \
	&& make promu \
	&& ln -s $GOPATH/bin/promu /bin/promu \
	&& make \
	&& make test

EXPOSE 9103 25826
ENTRYPOINT  [ "collectd_exporter" ]
