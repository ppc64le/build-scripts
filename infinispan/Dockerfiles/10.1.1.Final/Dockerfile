FROM registry.redhat.io/ubi8/ubi:latest

COPY infinispan_ppc64le.sh /

RUN chmod +x infinispan_ppc64le.sh 

RUN ./infinispan_ppc64le.sh

ENV DISTRIBUTION_URL https://downloads.jboss.org/infinispan/10.1.1.Final/infinispan-server-10.1.1.Final.zip

ENV HOME /opt/

ENV ISPN_HOME /opt/infinispan-server

USER root

RUN yum install unzip -y 

RUN INFINISPAN_SHA=$(curl $DISTRIBUTION_URL.sha1); curl -o /tmp/server.zip $DISTRIBUTION_URL && sha1sum /tmp/server.zip | grep $INFINISPAN_SHA \

    && unzip -q /tmp/server.zip -d $HOME && mv $HOME/infinispan-server-* $HOME/infinispan-server && rm /tmp/server.zip \ 

    && chown -R 1000.0 /opt/infinispan-server/ \

    && chmod -R g+rw /opt/infinispan-server/ \

    && find /opt/infinispan-server/ -type d -exec chmod g+x {} +

USER 1000

COPY config-generator.jar /opt/infinispan-server/bin

COPY launch.sh /bin

RUN chmod +x "/bin/launch.sh"

ENTRYPOINT ["/bin/launch.sh"]

EXPOSE 2157 7800 11221 11222 45700 57600
