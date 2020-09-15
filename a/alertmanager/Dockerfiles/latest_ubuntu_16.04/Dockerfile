FROM golang:1.9
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

RUN apt-get update \
	&& apt-get install wget git gcc make tar -y \
	&& mkdir -p $GOPATH/src/github.com/prometheus \
	&& cd $GOPATH/src/github.com/prometheus \
	&& git clone https://github.com/prometheus/alertmanager \
	&& cd alertmanager && git checkout v0.14.0 \
	#Build and test
	&& make build && make test \
	&& cp alertmanager /bin/ \
    && mkdir -p /etc/alertmanager/template \
    && mv ./doc/examples/simple.yml /etc/alertmanager/config.yml

EXPOSE     9093
VOLUME     [ "/alertmanager" ]
WORKDIR    /alertmanager
ENTRYPOINT [ "/bin/alertmanager" ]
CMD        [ "--config.file=/etc/alertmanager/config.yml", \
             "--storage.path=/alertmanager" ]
