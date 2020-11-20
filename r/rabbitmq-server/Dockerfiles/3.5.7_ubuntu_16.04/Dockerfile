FROM ppc64le/ubuntu:16.04

#Install Rabbitmq
RUN \
        apt-get update && \
        apt-get install -y rabbitmq-server
# /usr/sbin/rabbitmq-server has some irritating behavior, and only exists to "su - rabbitmq /usr/lib/rabbitmq/bin/rabbitmq-server ..."
ENV PATH /usr/lib/rabbitmq/bin:$PATH

# set home so that any `--user` knows where to put the erlang cookie
ENV HOME /var/lib/rabbitmq

RUN mkdir -p /var/lib/rabbitmq /etc/rabbitmq \
        && echo '[ { rabbit, [ { loopback_users, [ ] } ] } ].' > /etc/rabbitmq/rabbitmq.config \
        && chown -R rabbitmq:rabbitmq /var/lib/rabbitmq /etc/rabbitmq \
        && chmod -R 777 /var/lib/rabbitmq /etc/rabbitmq
VOLUME /var/lib/rabbitmq


### Expose Rabbitmq management console port and rabbitmq server port
EXPOSE 25672 15672 5672

#Start rabbitmq service
CMD ["rabbitmq-server"]
