#Copyright OpenSearch Contributors
# SPDX-License-Identifier: Apache-2.0
#
# Dockerfile for building an OpenSearch image using UBI9 instead of amazonlinux.
# It assumes that the working directory contains these files: an OpenSearch tarball (opensearch.tgz), log4j2.properties, opensearch.yml, opensearch-docker-entrypoint.sh, opensearch-onetime-setup.sh, opensearch-build.patch‎ and the snapshots of the plugins required .
# Build arguments:
#   VERSION: Required. Used to label the image.
#   BUILD_DATE: Required. Used to label the image. Should be in the form 'yyyy-mm-ddThh:mm:ssZ', i.e. a date-time from https://tools.ietf.org/html/rfc3339. The timestamp must be in UTC.
#   UID: Optional. Specify the opensearch userid. Defaults to 1000.
#   GID: Optional. Specify the opensearch groupid. Defaults to 1000.
#   OPENSEARCH_HOME: Optional. Specify the opensearch root directory. Defaults to /usr/share/opensearch.
#

########################### Stage 0 ########################
FROM registry.access.redhat.com/ubi10:latest AS linux_stage_0

ARG UID=1000
ARG GID=1000
ARG VERSION
ARG TEMP_DIR=/tmp/opensearch
ARG OPENSEARCH_HOME=/usr/share/opensearch
ARG OPENSEARCH_PATH_CONF=$OPENSEARCH_HOME/config
ARG SECURITY_PLUGIN_DIR=$OPENSEARCH_HOME/plugins/opensearch-security
ARG PERFORMANCE_ANALYZER_PLUGIN_CONFIG_DIR=$OPENSEARCH_PATH_CONF/opensearch-performance-analyzer

# Update packages
# Install the tools we need: tar and gzip to unpack the OpenSearch tarball, and shadow-utils to give us `groupadd` and `useradd`.
# Install which to allow running of securityadmin.sh
RUN dnf update -y && dnf install -y tar gzip shadow-utils which && dnf clean all

# Create an opensearch user, group
# OpenShift compatibility: Add user to root group (GID 0) for random UID support
RUN groupadd -g $GID opensearch && \
    adduser -u $UID -g $GID -G 0 -d $OPENSEARCH_HOME opensearch && \
    mkdir $TEMP_DIR

# Prepare working directory
# Copy artifacts and configurations to corresponding directories
COPY * $TEMP_DIR/
RUN ls -l $TEMP_DIR && \
    tar -xzpf /tmp/opensearch/opensearch-ppc64le.tgz -C $OPENSEARCH_HOME --strip-components=1 && \
    MAJOR_VERSION_ENTRYPOINT=`echo $VERSION | cut -d. -f1` && \
    echo $MAJOR_VERSION_ENTRYPOINT && \
    if ! (ls $TEMP_DIR | grep -E "opensearch-docker-entrypoint-.*.x.sh" | grep $MAJOR_VERSION_ENTRYPOINT); then MAJOR_VERSION_ENTRYPOINT="default"; fi && \
    mkdir -p $OPENSEARCH_HOME/data && chown -Rv $UID:$GID $OPENSEARCH_HOME/data && \
    if [[ -d $SECURITY_PLUGIN_DIR ]] ; then chmod -v 750 $SECURITY_PLUGIN_DIR/tools/* ; fi && \
    if [[ -d $PERFORMANCE_ANALYZER_PLUGIN_CONFIG_DIR ]] ; then cp -v $TEMP_DIR/performance-analyzer.properties $PERFORMANCE_ANALYZER_PLUGIN_CONFIG_DIR; fi && \
    cp -v $TEMP_DIR/opensearch-docker-entrypoint-$MAJOR_VERSION_ENTRYPOINT.x.sh $OPENSEARCH_HOME/opensearch-docker-entrypoint.sh && \
    cp -v $TEMP_DIR/opensearch-onetime-setup.sh $OPENSEARCH_HOME/ && \
    cp -v $TEMP_DIR/log4j2.properties $TEMP_DIR/opensearch.yml $OPENSEARCH_PATH_CONF/ && \
    ls -l $OPENSEARCH_HOME && \
    rm -rf $TEMP_DIR


########################### Stage 1 ########################
# Copy working directory to the actual release docker images
FROM registry.access.redhat.com/ubi10:latest

ARG UID=1000
ARG GID=1000
ARG OPENSEARCH_HOME=/usr/share/opensearch

# Update packages
# Install the tools we need: tar and gzip to unpack the OpenSearch tarball, and shadow-utils to give us `groupadd` and `useradd`.
# Install which to allow running of securityadmin.sh
RUN dnf update -y && dnf install -y tar gzip shadow-utils which && dnf clean all

# Create an opensearch user, group
RUN groupadd -g $GID opensearch && \
    adduser -u $UID -g $GID -d $OPENSEARCH_HOME opensearch

# Copy from Stage0
COPY --from=linux_stage_0 --chown=$UID:$GID $OPENSEARCH_HOME $OPENSEARCH_HOME
WORKDIR $OPENSEARCH_HOME

# Set $JAVA_HOME
RUN echo "export JAVA_HOME=$OPENSEARCH_HOME/jdk" >> /etc/profile.d/java_home.sh && \
    echo "export PATH=\$PATH:\$JAVA_HOME/bin" >> /etc/profile.d/java_home.sh && \
    ls -l $OPENSEARCH_HOME

ENV JAVA_HOME=$OPENSEARCH_HOME/jdk
ENV PATH=$PATH:$JAVA_HOME/bin:$OPENSEARCH_HOME/bin

# Add k-NN lib directory to library loading path variable
ENV LD_LIBRARY_PATH="$OPENSEARCH_HOME/plugins/opensearch-knn/lib"

# Disable FIPS approved-only mode to allow standard passwords
ENV OPENSEARCH_JAVA_OPTS="-Dorg.bouncycastle.fips.approved_only=false"

# OpenShift restricted-v2 compatibility: Fix ownership and permissions for random UID
# COPY --chown may not work correctly, so explicitly set ownership and permissions
RUN chown -R $UID:0 $OPENSEARCH_HOME && \
    chmod -R g=u $OPENSEARCH_HOME && \
    find $OPENSEARCH_HOME -type d -exec chmod g+x {} \; && \
    chmod g+x $OPENSEARCH_HOME/opensearch-docker-entrypoint.sh && \
    chmod g+x $OPENSEARCH_HOME/opensearch-onetime-setup.sh

# Change user
USER $UID

# Setup OpenSearch
# Disable security demo installation during image build, and allow user to disable during startup of the container
# Enable security plugin during image build, and allow user to disable during startup of the container
ARG DISABLE_INSTALL_DEMO_CONFIG=true
ARG DISABLE_SECURITY_PLUGIN=false
RUN ./opensearch-onetime-setup.sh

RUN --mount=type=secret,id=artifactory_user_secret,uid=$UID \
    --mount=type=secret,id=artifactory_token_secret,uid=$UID \
    export artifactory_user=$(cat /run/secrets/artifactory_user_secret) && \
    export artifactory_token=$(cat /run/secrets/artifactory_token_secret) && \
    curl -s -u ${artifactory_user}:${artifactory_token} -o opensearch-jvector-3.6.0.0.zip -L https://na.artifactory.swg-devops.com/artifactory/hyc-cpd-skywalker-team-lakehouse-on-prem-wxd-maven-local/power/opensearch/opensearch-jvector/opensearch-jvector-3.6.0.0.zip && \
    curl -s -u ${artifactory_user}:${artifactory_token} -o prometheus-exporter-3.6.0.0.zip -L https://na.artifactory.swg-devops.com/artifactory/hyc-cpd-skywalker-team-lakehouse-on-prem-wxd-maven-local/power/opensearch/prometheus-exporter/prometheus-exporter-3.6.0.0.zip && \
    curl -s -u ${artifactory_user}:${artifactory_token} -o opensearch-knn-3.6.0.0.zip -L https://na.artifactory.swg-devops.com/artifactory/hyc-cpd-skywalker-team-lakehouse-on-prem-wxd-maven-local/power/opensearch/opensearch-knn/opensearch-knn-3.6.0.0.zip && \
    curl -s -u ${artifactory_user}:${artifactory_token} -o opensearch-neural-search-3.6.0.0.zip -L https://na.artifactory.swg-devops.com/artifactory/hyc-cpd-skywalker-team-lakehouse-on-prem-wxd-maven-local/power/opensearch/opensearch-neural-search/opensearch-neural-search-3.6.0.0-20260716.zip && \
    echo y | opensearch-plugin install file://`pwd`/opensearch-knn-3.6.0.0.zip && \
    echo y | opensearch-plugin install file://`pwd`/opensearch-neural-search-3.6.0.0.zip

# Expose ports for the opensearch service (9200 for HTTP and 9300 for internal transport) and performance analyzer (9600 for the agent and 9650 for the root cause analysis component)
EXPOSE 9200 9300 9600 9650

ARG VERSION
ARG BUILD_DATE
ARG NOTES

# Label
LABEL org.label-schema.schema-version="1.0" \
  org.label-schema.name="opensearch" \
  org.label-schema.version="$VERSION" \
  org.label-schema.url="https://opensearch.org" \
  org.label-schema.vcs-url="https://github.com/opensearch-project/OpenSearch" \
  org.label-schema.license="Apache-2.0" \
  org.label-schema.vendor="OpenSearch" \
  org.label-schema.description="$NOTES" \
  org.label-schema.build-date="$BUILD_DATE"

# CMD to run
ENTRYPOINT ["./opensearch-docker-entrypoint.sh"]
CMD ["opensearch"]
