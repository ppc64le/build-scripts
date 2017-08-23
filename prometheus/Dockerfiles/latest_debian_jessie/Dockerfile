FROM ppc64le/golang:1.8

MAINTAINER Snehlata Mohite <smohite@us.ibm.com>

ENV PROMETHEUS_HOME /go/src/github.com/prometheus/prometheus

RUN  go get github.com/prometheus/prometheus/... \
     && cd ${PROMETHEUS_HOME} && make all\
     && cp  ${PROMETHEUS_HOME}/prometheus /bin/prometheus\
     && cp ${PROMETHEUS_HOME}/promtool   /bin/promtool\
     && mkdir /etc/prometheus/\
     && cp ${PROMETHEUS_HOME}/documentation/examples/prometheus.yml /etc/prometheus/

VOLUME     [ "/prometheus" ]
EXPOSE 9090

CMD [ "/bin/prometheus","-config.file=/etc/prometheus/prometheus.yml","-storage.local.path=/prometheus"]
