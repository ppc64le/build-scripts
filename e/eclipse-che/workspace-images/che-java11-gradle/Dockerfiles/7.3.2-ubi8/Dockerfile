FROM registry.redhat.io/openjdk/openjdk-11-rhel8

CMD ["gradle"]

ENV GRADLE_HOME /opt/gradle

USER root
RUN set -o errexit -o nounset \
    && echo "Adding gradle user and group" \
    && groupadd --system --gid 1000 gradle \
    && useradd --system --gid gradle --uid 1000 --shell /bin/bash --create-home gradle \
    && mkdir /home/gradle/.gradle \
    && chown --recursive gradle:gradle /home/gradle \
    \
    && echo "Symlinking root Gradle cache to gradle Gradle cache" \
    && ln -s /home/gradle/.gradle /root/.gradle

VOLUME /home/gradle/.gradle

WORKDIR /home/gradle
USER root

RUN yum update -y && yum install unzip && yum install unzip && yum clean all

#RUN yum update \
#    && yum install --yes --no-install-recommends \
#        fontconfig \
#        unzip \
#        wget \
#        \
#        bzr \
#        git \
#        git-lfs \
#        mercurial \
#        openssh-client \
#        subversion \
#    && rm -rf /var/lib/apt/lists/*

ENV GRADLE_VERSION 6.1.1
ARG GRADLE_DOWNLOAD_SHA256=9d94e6e4a28ad328072ef6e56bce79a810494ae756751fdcedffdeaf27c093b1
RUN set -o errexit -o nounset \
    && echo "Downloading Gradle" \
    && curl -fsSL -o /tmp/gradle-${GRADLE_VERSION}-bin.zip "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" \
    \
    && echo "Checking download hash" \
    && echo "${GRADLE_DOWNLOAD_SHA256} /tmp/gradle-${GRADLE_VERSION}-bin.zip" | sha256sum --check - \
    \
    && echo "Installing Gradle" \
    && unzip /tmp/gradle-${GRADLE_VERSION}-bin.zip \
    && rm /tmp/gradle-${GRADLE_VERSION}-bin.zip \
    && mv "gradle-${GRADLE_VERSION}" "${GRADLE_HOME}/" \
    && ln --symbolic "${GRADLE_HOME}/bin/gradle" /usr/bin/gradle \
    \
    && echo "Testing Gradle installation" \
    && gradle --version
