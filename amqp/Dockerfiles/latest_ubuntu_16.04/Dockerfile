FROM ppc64le/ubuntu:16.04
MAINTAINER "Atul Sowani <sowania@us.ibm.com>"

RUN mkdir /tmp/AMQP
ENV GOPATH /tmp/AMQP

RUN apt-get update -y && \
    apt-get install -y git golang-go rabbitmq-server && \
    go get github.com/streadway/amqp && \
    apt-get remove -y --purge git golang-go && apt-get autoremove -y
EXPOSE 5672
CMD service rabbitmq-server start && cat /var/log/rabbitmq/startup_log && bash
