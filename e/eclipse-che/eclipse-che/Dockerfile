FROM registry.access.redhat.com/ubi8/ubi

# Install packages necessary to run EAP
RUN yum update -y && yum -y install bsdtar unzip && yum clean all

# Create a user and group used to launch processes
# The user ID 1000 is the default for the first "regular" user on Fedora/RHEL,
# so there is a high chance that this ID will be equal to the current user
# making it easier to use volumes (no permission issues)

RUN groupadd -r jboss -g 1000 && useradd -u 1000 -r -g jboss -m -d /opt/jboss -s /sbin/nologin -c "JBoss user" jboss && \
    chmod 755 /opt/jboss

# Set the working directory to jboss' user home directory
WORKDIR /opt/jboss

RUN yum -y install java-1.8.0-openjdk-devel && yum clean all

# Specify the user which should be used to execute all commands below
USER jboss

ENV JAVA_HOME /usr/lib/jvm/java

ENV KEYCLOAK_VERSION 6.0.1
ENV JDBC_POSTGRES_VERSION 42.2.5
ENV JDBC_MYSQL_VERSION 5.1.46
ENV JDBC_MARIADB_VERSION 2.2.3

ENV LAUNCH_JBOSS_IN_BACKGROUND 1
ENV PROXY_ADDRESS_FORWARDING false
ENV JBOSS_HOME /opt/jboss/keycloak
ENV LANG en_US.UTF-8

ARG GIT_REPO
ARG GIT_BRANCH
ARG KEYCLOAK_DIST=https://downloads.jboss.org/keycloak/$KEYCLOAK_VERSION/keycloak-$KEYCLOAK_VERSION.tar.gz

USER root

RUN yum update -y && yum install -y  git && yum install -y openssl which && yum clean all

ADD tools /opt/jboss/tools
RUN /opt/jboss/tools/build-keycloak.sh

USER 1000

EXPOSE 8080

ENTRYPOINT [ "/opt/jboss/tools/docker-entrypoint.sh" ]

CMD ["-b", "0.0.0.0"]
