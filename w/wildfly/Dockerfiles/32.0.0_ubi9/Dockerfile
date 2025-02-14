FROM registry.access.redhat.com/ubi9/ubi-minimal:9.3

RUN  microdnf install --best --nodocs -y tar gzip zip shadow-utils && microdnf clean all

WORKDIR /opt/jboss

RUN groupadd -r jboss -g 1000 && useradd -u 1000 -r -g jboss -m -d /opt/jboss -s /sbin/nologin -c "JBoss user" jboss && \
    chmod 755 /opt/jboss

# Set the PACKAGE_VERSION env variable
ENV PACKAGE_VERSION 32.0.0.Final
ENV WILDFLY_SHA1=9b6d762aa4662045fc3e7329a1ed1c0d457daf6d
ENV JBOSS_HOME /opt/jboss/wildfly

USER root

# Add the WildFly distribution to /opt, and make wildfly the owner of the extracted tar content
# Make sure the distribution is available from a well-known place
RUN cd $HOME \
    && curl -L -O https://github.com/wildfly/wildfly/releases/download/$PACKAGE_VERSION/wildfly-$PACKAGE_VERSION.tar.gz \
    && sha1sum wildfly-$PACKAGE_VERSION.tar.gz | grep $WILDFLY_SHA1 \
    && tar -xf wildfly-$PACKAGE_VERSION.tar.gz \
    && mv $HOME/wildfly-$PACKAGE_VERSION $JBOSS_HOME \
    && rm wildfly-$PACKAGE_VERSION.tar.gz \
    && chown -R jboss:0 ${JBOSS_HOME} \
    && chmod -R g+rw ${JBOSS_HOME}

# Ensure signals are forwarded to the JVM process correctly for graceful shutdown
ENV LAUNCH_JBOSS_IN_BACKGROUND true

USER jboss

# Expose the ports in which we're interested
EXPOSE 8080

# Set the default command to run on boot
# This will boot WildFly in standalone mode and bind to all interfaces
CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0"]
