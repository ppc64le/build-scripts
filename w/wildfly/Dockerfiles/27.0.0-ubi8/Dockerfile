FROM registry.access.redhat.com/ubi8/ubi:8.4

# Set the WILDFLY_VERSION env variable
ENV WILDFLY_VERSION=26.1.2.Final
ENV WILDFLY_SHA1=3dda0f3795c00cedf8b14c83f8c341244e7cad44
ENV JBOSS_HOME=/opt/jboss/wildfly

# Add the WildFly distribution to /opt, and make wildfly the owner of the extracted tar content
# Make sure the distribution is available from a well-known place
RUN yum install -y java-11-openjdk-devel \
    && mkdir -p /opt/jboss && cd $HOME \
    && curl -L -O https://github.com/wildfly/wildfly/releases/download/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.tar.gz \
    && sha1sum wildfly-$WILDFLY_VERSION.tar.gz | grep $WILDFLY_SHA1 \
    && tar xf wildfly-$WILDFLY_VERSION.tar.gz \
    && mv $HOME/wildfly-$WILDFLY_VERSION $JBOSS_HOME \
    && rm wildfly-$WILDFLY_VERSION.tar.gz \
    && chown -R 1001:1001 ${JBOSS_HOME} \
    && chmod -R g+rw ${JBOSS_HOME}


# Ensure signals are forwarded to the JVM process correctly for graceful shutdown
ENV LAUNCH_JBOSS_IN_BACKGROUND true

USER 1001

EXPOSE 8080

# Set the default command to run on boot
# This will boot WildFly in standalone mode and bind to all interfaces
CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0"]
