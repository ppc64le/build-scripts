# Stage 1: build the Logstash OSS tarball for ppc64le
FROM registry.access.redhat.com/ubi9/ubi:latest AS build

ARG PACKAGE_VERSION=v9.4.5
# ARG PATCH=https://raw.githubusercontent.com/ppc64le/build-scripts/master/l/logstash/assemble-tar-withoutjdk.patch
ENV PACKAGE_NAME=logstash

# Install build dependencies
RUN yum -y update && yum install -y \
    git procps yum-utils wget ncurses make gcc-c++ libffi-devel \
    java-21-openjdk java-21-openjdk-devel java-21-openjdk-headless

# Add CentOS Stream 9 repos for bison and readline-devel (not in UBI9)
RUN rpm --import https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official && \
    cat > /etc/yum.repos.d/cs9-appstream.repo << 'EOF'
[cs9-appstream]
name=CentOS Stream 9 - AppStream
baseurl=https://mirror.stream.centos.org/9-stream/AppStream/ppc64le/os/
gpgcheck=1
gpgkey=https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official
enabled=1
EOF
RUN cat > /etc/yum.repos.d/cs9-baseos.repo << 'EOF'
[cs9-baseos]
name=CentOS Stream 9 - BaseOS
baseurl=https://mirror.stream.centos.org/9-stream/BaseOS/ppc64le/os/
gpgcheck=1
gpgkey=https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official
enabled=1
EOF
RUN cat > /etc/yum.repos.d/cs9-crb.repo << 'EOF'
[cs9-crb]
name=CentOS Stream 9 - CRB
baseurl=https://mirror.stream.centos.org/9-stream/CRB/ppc64le/os/
gpgcheck=1
gpgkey=https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official
enabled=1
EOF
RUN yum install -y bison readline-devel

WORKDIR /tmp

RUN git clone https://github.com/elastic/logstash ${PACKAGE_NAME} && \
    cd ${PACKAGE_NAME} && \
    git checkout ${PACKAGE_VERSION} && \
    git describe --tags --exact-match

# Apply ppc64le patch
COPY logstash_v9.4.5.patch /tmp/logstash_v9.4.5.patch
RUN cd ${PACKAGE_NAME} && \
    git apply /tmp/logstash_v9.4.5.patch && \
    rm /tmp/logstash_v9.4.5.patch

# Install RVM and the Ruby version required by Logstash
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

# Download and unpack the ppc64le JDK; writes JDK_VERSION file expected by the rake task
RUN /bin/bash -l -c "\
    source /usr/local/rvm/scripts/rvm && \
    cd /tmp/${PACKAGE_NAME} && \
    ARCH=ppc64le ./gradlew copyAllJdks --rerun-tasks --no-build-cache"

# Ensure JDK_VERSION file exists (written by copyAllJdks doLast from jdk-linux-ppc64le/release)
RUN cd /tmp/${PACKAGE_NAME} && \
    if [ ! -f JDK_VERSION ]; then \
      JDK_REL=jdk-linux-ppc64le/release; \
      if [ ! -f "$JDK_REL" ]; then \
        echo "ERROR: JDK_VERSION missing and $JDK_REL not found — copyAllJdks did not complete" >&2; exit 1; \
      fi; \
      grep IMPLEMENTOR_VERSION "$JDK_REL" | sed 's/IMPLEMENTOR_VERSION="//;s/"//' > JDK_VERSION; \
    fi

# Install gems into the vendored JRuby (avoids Bundler double-load conflict with system Ruby)
RUN /bin/bash -l -c "\
    source /usr/local/rvm/scripts/rvm && \
    cd /tmp/${PACKAGE_NAME} && \
    cp Gemfile.jruby-3.4.lock.release Gemfile.lock && \
    vendor/jruby/bin/jruby -S gem install bundler --no-document && \
    vendor/jruby/bin/jruby -S bundle install --without development test"

# Build the OSS tarball
RUN /bin/bash -l -c "\
    source /usr/local/rvm/scripts/rvm && \
    cd /tmp/${PACKAGE_NAME} && \
    ARCH=ppc64le \
    BUNDLE_WITHOUT='development:test' \
    RELEASE=1 \
    vendor/jruby/bin/jruby -S bundle exec rake artifact:archives_oss"

# ─────────────────────────────────────────────────────────────
# Stage 2: install the tarball on a clean UBI9-minimal base
# ─────────────────────────────────────────────────────────────
FROM redhat/ubi9-minimal:latest

ENV ELASTIC_CONTAINER=true
ENV PATH=/usr/share/logstash/bin:$PATH
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

WORKDIR /usr/share

# Install packages
RUN \
  microdnf install -y procps findutils tar gzip && \
  microdnf install -y openssl && \
  microdnf install -y which shadow-utils && \
  microdnf clean all

# Provide a non-root user to run the process.
# Mount the tarball from the build stage directly — no COPY layer, no intermediate file on disk.
# This keeps the final image size on par with the x86_64 build.
RUN --mount=type=bind,from=build,source=/tmp/logstash/build/logstash-oss-9.4.5-linux-ppc64le.tar.gz,target=/tmp/logstash.tar.gz \
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
  org.label-schema.version="9.4.5" \
  org.opencontainers.image.created="" \
  org.opencontainers.image.description="Logstash is a free and open server-side data processing pipeline that ingests data from a multitude of sources, transforms it, and then sends it to your favorite 'stash.'" \
  org.opencontainers.image.licenses="Apache 2.0" \
  org.opencontainers.image.title="logstash" \
  org.opencontainers.image.vendor="Elastic" \
  org.opencontainers.image.version="9.4.5" \
  description="Logstash is a free and open server-side data processing pipeline that ingests data from a multitude of sources, transforms it, and then sends it to your favorite 'stash.'" \
  license="Apache 2.0" \
  maintainer="info@elastic.co" \
  name="logstash" \
  summary="Logstash is a free and open server-side data processing pipeline that ingests data from a multitude of sources, transforms it, and then sends it to your favorite 'stash.'" \
  vendor="Elastic"

ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
