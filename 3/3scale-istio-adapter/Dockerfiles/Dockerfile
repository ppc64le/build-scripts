FROM registry.access.redhat.com/ubi8/ubi:latest

MAINTAINER Krishna Harsha Voora <krishvoor@in.ibm.com>

ENV THREESCALE_LISTEN_ADDR 3333
EXPOSE 3333
EXPOSE 8080

ADD build.sh /root/

RUN /root/build.sh

WORKDIR /app/
CMD ./3scale-istio-adapter
