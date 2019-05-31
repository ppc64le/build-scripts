FROM golang:1.12

LABEL maintainer="Shivani Junawane <shivanij@us.ibm.com>"

WORKDIR /data

RUN git clone https://github.com/prometheus/pushgateway.git \
        && cd pushgateway && git checkout v0.7.0 \
        && make all \
        && cp pushgateway /bin/pushgateway \
        && rm -rf pushgateway

EXPOSE 9091
WORKDIR /pushgateway
CMD [ "/bin/pushgateway" ]
