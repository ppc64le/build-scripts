FROM ppc64le/node:10.11-stretch

# Owner information
MAINTAINER "Priya Seth <sethp@us.ibm.com>"

#Install dependencies needed for building and testing
RUN apt-get update && apt-get install -y build-essential rabbitmq-server stompserver && \
        git clone https://github.com/strongloop/strong-mq.git && cd strong-mq && \
        service rabbitmq-server start && service stompserver start && \
        npm install && npm test && \
        apt-get purge -y build-essential && apt-get autoremove -y

WORKDIR /strong-mq

CMD ["/bin/bash"]

