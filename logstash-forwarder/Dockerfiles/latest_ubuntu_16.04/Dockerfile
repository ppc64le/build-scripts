FROM ppc64le/golang:1.8
MAINTAINER "Atul Sowani <sowania@us.ibm.com>"

ENV PATH /usr/local/gccgo/bin:/opt/logstash-forwarder/bin:$PATH
ENV LD_LIBRARY_PATH /usr/local/gccgo/lib64

RUN apt-get update -y && \
    apt-get install -y ruby-dev git libffi-dev build-essential ruby && \
    git clone https://github.com/elastic/logstash-forwarder.git --branch master && \
    cd logstash-forwarder && \
    go build -gccgoflags '-static-libgo' -o logstash-forwarder && \
    gem install bundler && bundle install && make deb && \
    dpkg -i /go/logstash-forwarder/logstash-forwarder_0.4.0_ppc64el.deb && \
    apt-get -y remove --purge ruby-dev git libffi-dev build-essential ruby

# Define mountable directories.
RUN mkdir -p /opt/certs
RUN touch /var/log/syslog
VOLUME ["/opt/certs"]

# Define working directory.
WORKDIR /logstash-forwarder
COPY logstash-forwarder.conf /logstash-forwarder/logstash-forwarder.conf

EXPOSE 5000
CMD ["/opt/logstash-forwarder/bin/logstash-forwarder", "-config=/logstash-forwarder/logstash-forwarder.conf"]
