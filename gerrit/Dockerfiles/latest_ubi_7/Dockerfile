FROM registry.access.redhat.com/ubi7/ubi:latest

# Required Labels
LABEL name="gerrit" \
      maintainer="redmark@us.ibm.com" \
      vendor="Google" \
      version="3.0.3" \
      release="1" \
      summary="Red Hat UBI Gerrit Code Review" \
      description="Red Hat UBI Gerrit Code Review Application"

COPY licenses /licenses

RUN yum update -y -q && yum install -y -q sudo \
  && useradd --create-home --home-dir /home/gerrit --shell /bin/bash --system --user-group gerrit \
  && echo '%gerrit ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER gerrit
WORKDIR /home/gerrit

RUN sudo yum update -y -q \
  && sudo yum install java-1.8.0-openjdk-devel wget git -q -y

# Using the released Gerrit WAR file
ENV GERRIT_WAR_VER gerrit-3.0.3.war
ENV GERRIT_SITE /home/gerrit/gerrit_testsite
ENV JAVA_HOME /usr/lib/jvm/java-1.8.0-openjdk
ENV PATH /usr/lib/jvm/java-1.8.0-openjdk/bin/:$PATH

RUN wget https://gerrit-releases.storage.googleapis.com/${GERRIT_WAR_VER} --no-check-certificate --quiet \
  && java -jar ${GERRIT_WAR_VER} init --batch --dev --install-all-plugins -d ${GERRIT_SITE} \
  && git config -f ${GERRIT_SITE}/etc/gerrit.config --add container.javaOptions "-Djava.security.egd=file:/dev/./urandom" \
  && git config --file ${GERRIT_SITE}/etc/gerrit.config gerrit.canonicalWebUrl "${CANONICAL_WEB_URL:-http://$HOSTNAME}" \
  && git config --file ${GERRIT_SITE}/etc/gerrit.config noteDb.changes.autoMigrate true

ENV CANONICAL_WEB_URL=

EXPOSE 29418 8080

VOLUME ["/home/gerrit/gerrit_testsite/git", "/home/gerrit/gerrit_testsite/index", "/home/gerrit/gerrit_testsite/cache", "/home/gerrit/gerrit_testsite/db", "/home/gerrit/gerrit_testsite/etc"]

# We don't what the container to exit once Gerrit has started so add the tail to keep it running
CMD ${GERRIT_SITE}/bin/gerrit.sh run && tail -f /dev/null
