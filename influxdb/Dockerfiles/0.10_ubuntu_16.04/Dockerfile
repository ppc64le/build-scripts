FROM ppc64le/ubuntu:16.04

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

RUN apt-get update -y && \
	apt-get install -y influxdb

COPY influxdb.conf /etc/influxdb/influxdb.conf

EXPOSE 8086

VOLUME /var/lib/influxdb

CMD ["influxd"]
