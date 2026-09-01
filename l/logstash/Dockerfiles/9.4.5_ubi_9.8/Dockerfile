# syntax=docker/dockerfile:1
FROM registry.access.redhat.com/ubi9/ubi:9.8 AS build

ARG PACKAGE_VERSION=v9.4.5
# PATCH is pinned to v9.4.5 intentionally; newer versions may not have a patch available
ARG PATCH=https://raw.githubusercontent.com/ppc64le/build-scripts/master/l/logstash/logstash_v9.4.5.patch
ENV PACKAGE_NAME=logstash

RUN yum -y update && yum install -y \
    git procps yum-utils wget ncurses make gcc-c++ libffi-devel \
    java-21-openjdk java-21-openjdk-devel java-21-openjdk-headless

# bison and readline-devel are not in UBI9; add CentOS Stream 9 repos
RUN rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official && \
    printf '[cs9-appstream]\nname=CentOS Stream 9 - AppStream\nbaseurl=https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/\ngpgcheck=1\ngpgkey=https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official\nenabled=1\n' \
        > /etc/yum.repos.d/cs9-appstream.repo && \
    printf '[cs9-baseos]\nname=CentOS Stream 9 - BaseOS\nbaseurl=https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/\ngpgcheck=1\ngpgkey=https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official\nenabled=1\n' \
        > /etc/yum.repos.d/cs9-baseos.repo && \
    printf '[cs9-crb]\nname=CentOS Stream 9 - CRB\nbaseurl=https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/\ngpgcheck=1\ngpgkey=https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official\nenabled=1\n' \
        > /etc/yum.repos.d/cs9-crb.repo && \
    yum install -y bison readline-devel

WORKDIR /tmp

RUN wget --https-only "${PATCH}" && \
    git clone https://github.com/elastic/logstash ${PACKAGE_NAME} && \
    cd ${PACKAGE_NAME} && \
    git checkout ${PACKAGE_VERSION} && \
    git apply --check ../${PATCH##*/} && \
    git apply --ignore-whitespace ../${PATCH##*/} && \
    rm -f /tmp/${PATCH##*/}

# Install RVM using the upstream method (build stage only).
# RVM's bootstrap requires piping to bash; this is the upstream-mandated install path (no alternative exists).
RUN curl -sSL https://rvm.io/mpapis.asc | gpg2 --import - && \
    curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import - && \
    curl -L https://get.rvm.io | bash -s stable
RUN /bin/bash -l -c "\
    source /etc/profile.d/rvm.sh && \
    rvm install \$(cat /tmp/${PACKAGE_NAME}/.ruby-version) && \
    rvm use \$(cat /tmp/${PACKAGE_NAME}/.ruby-version) --default"

ENV OSS=true
ENV LOGSTASH_SOURCE=1
ENV LOGSTASH_PATH=/tmp/logstash

# Download ppc64le JDK via copyAllJdks; writes JDK_VERSION used by artifact:archives_oss
RUN /bin/bash -l -c "\
    source /usr/local/rvm/scripts/rvm && \
    cd /tmp/${PACKAGE_NAME} && \
    ARCH=ppc64le ./gradlew copyAllJdks --rerun-tasks --no-build-cache"

# Fallback: write JDK_VERSION if copyAllJdks did not produce it
RUN cd /tmp/${PACKAGE_NAME} && \
    if [ ! -f JDK_VERSION ]; then \
      JDK_REL=jdk-linux-ppc64le/release; \
      if [ ! -f "$JDK_REL" ]; then \
        echo "ERROR: JDK_VERSION missing and $JDK_REL not found - copyAllJdks did not complete" >&2; exit 1; \
      fi; \
      grep IMPLEMENTOR_VERSION "$JDK_REL" | sed 's/IMPLEMENTOR_VERSION="//;s/"//' > JDK_VERSION; \
    fi

# Install gems via vendored JRuby to avoid Bundler conflict with system Ruby
RUN /bin/bash -l -c "\
    source /usr/local/rvm/scripts/rvm && \
    cd /tmp/${PACKAGE_NAME} && \
    cp Gemfile.jruby-3.4.lock.release Gemfile.lock && \
    vendor/jruby/bin/jruby -S gem install bundler --no-document && \
    vendor/jruby/bin/jruby -S bundle install --without development test"

RUN /bin/bash -l -c "\
    source /usr/local/rvm/scripts/rvm && \
    cd /tmp/${PACKAGE_NAME} && \
    ARCH=ppc64le \
    BUNDLE_WITHOUT='development:test' \
    RELEASE=1 \
    vendor/jruby/bin/jruby -S bundle exec rake artifact:archives_oss"

# Rename the versioned tarball to a fixed name; runtime stage mounts it by this fixed path
RUN VERSION="${PACKAGE_VERSION#v}" && \
    mv /tmp/logstash/build/logstash-oss-${VERSION}-linux-ppc64le.tar.gz \
       /tmp/logstash/build/logstash-oss.tar.gz

# Stage 2: runtime image
FROM registry.access.redhat.com/ubi9/ubi-minimal:9.8

ARG PACKAGE_VERSION=v9.4.5

ENV ELASTIC_CONTAINER=true
ENV PATH=/usr/share/logstash/bin:$PATH
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

WORKDIR /usr/share

RUN microdnf install -y \
        procps \
        findutils \
        tar \
        gzip \
        openssl \
        which \
        shadow-utils \
    && microdnf clean all

RUN --mount=type=bind,from=build,source=/tmp/logstash/build/logstash-oss.tar.gz,target=/tmp/logstash.tar.gz \
  groupadd --gid 1000 logstash && \
  adduser --uid 1000 --gid 1000 \
  --home "/usr/share/logstash" \
  --no-create-home \
  logstash && \
  tar -zxf /tmp/logstash.tar.gz -C /usr/share && \
  mv /usr/share/logstash-* /usr/share/logstash && \
  chown -R logstash:root /usr/share/logstash && \
  chmod -R g=u /usr/share/logstash && \
  mkdir /licenses && \
  mv /usr/share/logstash/NOTICE.TXT /licenses/NOTICE.TXT && \
  mv /usr/share/logstash/LICENSE.txt /licenses/LICENSE.txt && \
  find /usr/share/logstash -type d -exec chmod g+s {} \; && \
  ln -s /usr/share/logstash /opt/logstash

COPY --from=build --chown=logstash:root /tmp/logstash/docker/data/logstash/env2yaml/classes /usr/share/logstash/env2yaml/classes/
COPY --from=build --chown=logstash:root /tmp/logstash/docker/data/logstash/env2yaml/lib     /usr/share/logstash/env2yaml/lib/
COPY --from=build --chmod=0755          /tmp/logstash/docker/data/logstash/env2yaml/env2yaml /usr/local/bin/env2yaml
COPY --from=build --chown=logstash:root /tmp/logstash/docker/data/logstash/config/pipelines.yml          /usr/share/logstash/config/pipelines.yml
COPY --from=build --chown=logstash:root /tmp/logstash/docker/data/logstash/config/log4j2.properties      /usr/share/logstash/config/log4j2.properties
COPY --from=build --chown=logstash:root /tmp/logstash/docker/data/logstash/config/log4j2.file.properties /usr/share/logstash/config/log4j2.file.properties
COPY --from=build --chown=logstash:root /tmp/logstash/docker/data/logstash/config/logstash-oss.yml       /usr/share/logstash/config/logstash.yml
COPY --from=build --chown=logstash:root /tmp/logstash/docker/data/logstash/pipeline/default.conf         /usr/share/logstash/pipeline/logstash.conf
COPY --from=build --chmod=0755          /tmp/logstash/docker/data/logstash/bin/docker-entrypoint         /usr/local/bin/docker-entrypoint

WORKDIR /usr/share/logstash

USER 1000

EXPOSE 9600 5044

LABEL org.label-schema.build-date="" \
  org.label-schema.license="Apache 2.0" \
  org.label-schema.name="logstash" \
  org.label-schema.schema-version="1.0" \
  org.label-schema.url="https://www.elastic.co/products/logstash" \
  org.label-schema.vcs-url="https://github.com/elastic/logstash" \
  org.label-schema.vendor="Elastic" \
  org.label-schema.version="${PACKAGE_VERSION}" \
  org.opencontainers.image.created="" \
  org.opencontainers.image.description="Logstash is a free and open server-side data processing pipeline that ingests data from a multitude of sources, transforms it, and then sends it to your favorite 'stash.'" \
  org.opencontainers.image.licenses="Apache 2.0" \
  org.opencontainers.image.title="logstash" \
  org.opencontainers.image.vendor="Elastic" \
  org.opencontainers.image.version="${PACKAGE_VERSION}" \
  description="Logstash is a free and open server-side data processing pipeline that ingests data from a multitude of sources, transforms it, and then sends it to your favorite 'stash.'" \
  license="Apache 2.0" \
  maintainer="info@elastic.co" \
  name="logstash" \
  summary="Logstash is a free and open server-side data processing pipeline that ingests data from a multitude of sources, transforms it, and then sends it to your favorite 'stash.'" \
  vendor="Elastic"

ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]

