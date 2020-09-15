FROM ppc64le/ubuntu:16.04
MAINTAINER "Vibhuti Sawant <Vibhuti.Sawant@ibm.com>"

RUN mkdir /tmp/AMQP
ENV GOPATH /tmp/AMQP
ENV PATH=/usr/lib/go-1.10/bin:$PATH

RUN apt-get update -y && \
    apt-get install -y git golang-1.10-go rabbitmq-server && \
    go get github.com/streadway/amqp && \
    apt-get remove -y --purge git golang-1.10-go && apt-get autoremove -y
EXPOSE 5672
CMD service rabbitmq-server start && cat /var/log/rabbitmq/startup_log && bash
