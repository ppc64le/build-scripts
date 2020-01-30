########################################################################################################################
# Dockerfile to run a tiDB Container
# Docker build command:
# docker build -t tidb .
# Docker run command:
# docker run -p <port>:4000 -d -t tidb
########################################################################################################################

FROM registry.access.redhat.com/ubi8/ubi:latest

LABEL name="rhosp13/tidb" \
      maintainer="sarvesh.tamba@ibm.com" \
      vendor="VendorX" \
      version="2.0.10" \
      release="1" \
      summary="Red Hat OpenStack Platform 13.0 tiDB" \
      description="Red Hat OpenStack Platform 13.0 tiDB"

ENV GOPATH "/root/go"
ENV PATH $PATH:$GOPATH/bin

RUN yum update -y && yum install -y git go make \
 && mkdir -p /root/go/src/github.com/pingcap \
 && cd /root/go/src/github.com/pingcap \
 && git clone https://github.com/pingcap/tidb.git \
 && mkdir /logs \
 && touch /logs/unit-test \
 && cd tidb \
 && git checkout v2.0.10  \
 && mkdir /licenses && cp LICENSE /licenses/licensing.txt \
 && make default \
 && cp bin/goyacc /bin && cp bin/tidb-server /bin


RUN groupadd tidb && useradd -r -g tidb tidb -m -d /home/tidb/

USER tidb

WORKDIR /home/tidb

EXPOSE 4000

ENTRYPOINT ["tidb-server"]

CMD ["bash"]

