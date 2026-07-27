# Copyright OpenSearch Contributors
# SPDX-License-Identifier: Apache-2.0


# This dockerfile generates an AmazonLinux-based image containing an OpenSearch installation (2.x and above since release 2.10.0).
# Dockerfile for building an OpenSearch image.
# It assumes that the working directory contains these files: an OpenSearch tarball (opensearch.tgz), log4j2.properties, opensearch.yml, opensearch-docker-entrypoint.sh, opensearch-onetime-setup.sh.
# Build arguments:
#   VERSION: Required. Used to label the image.
#   BUILD_DATE: Required. Used to label the image. Should be in the form 'yyyy-mm-ddThh:mm:ssZ', i.e. a date-time from https://tools.ietf.org/html/rfc3339. The timestamp must be in UTC.
#   UID: Optional. Specify the opensearch userid. Defaults to 1000.
#   GID: Optional. Specify the opensearch groupid. Defaults to 1000.
#   OPENSEARCH_HOME: Optional. Specify the opensearch root directory. Defaults to /usr/share/opensearch.


########################### Stage 0 ########################
FROM registry.access.redhat.com/ubi9/ubi:latest AS linux_stage_0

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

# Create an opensearch user, group, and directory
RUN groupadd -g $GID opensearch && \
    adduser -u $UID -g $GID -d $OPENSEARCH_HOME opensearch && \
    mkdir $TEMP_DIR

# Prepare working directory
# Copy artifacts and configurations to corresponding directories
COPY * $TEMP_DIR/
RUN ls -l $TEMP_DIR && \
    tar -xzpf /tmp/opensearch/opensearch-core-`uname -p`.tgz -C $OPENSEARCH_HOME --strip-components=1 && \
    MAJOR_VERSION_ENTRYPOINT=`echo $VERSION | cut -d. -f1` && \
    echo $MAJOR_VERSION_ENTRYPOINT && \
    if ! (ls $TEMP_DIR | grep -E "opensearch-docker-entrypoint-.*.x.sh" | grep $MAJOR_VERSION_ENTRYPOINT); then MAJOR_VERSION_ENTRYPOINT="default"; fi && \
    mkdir -p $OPENSEARCH_HOME/data && chown -Rv $UID:$GID $OPENSEARCH_HOME/data && \
    mkdir -p $OPENSEARCH_PATH_CONF && \
    if [[ -d $SECURITY_PLUGIN_DIR ]] ; then chmod -v 750 $SECURITY_PLUGIN_DIR/tools/* ; fi && \
    if [[ -d $PERFORMANCE_ANALYZER_PLUGIN_CONFIG_DIR ]] ; then cp -v $TEMP_DIR/performance-analyzer.properties $PERFORMANCE_ANALYZER_PLUGIN_CONFIG_DIR; fi && \
    cp -v $TEMP_DIR/opensearch-docker-entrypoint-$MAJOR_VERSION_ENTRYPOINT.x.sh $OPENSEARCH_HOME/opensearch-docker-entrypoint.sh && \
    cp -v $TEMP_DIR/opensearch-onetime-setup.sh $OPENSEARCH_HOME/ && \
    cp -v $TEMP_DIR/log4j2.properties $TEMP_DIR/opensearch.yml $OPENSEARCH_PATH_CONF/ && \
    ls -l $OPENSEARCH_HOME && \
    rm -rf $TEMP_DIR


########################### Stage 1 ########################
# Copy working directory to the actual release docker images
FROM registry.access.redhat.com/ubi9/ubi:latest

ARG UID=1000
ARG GID=1000
ARG OPENSEARCH_HOME=/usr/share/opensearch

# Update packages
# Install the tools we need: tar and gzip to unpack the OpenSearch tarball, and shadow-utils to give us `groupadd` and `useradd`.
# Install which to allow running of securityadmin.sh
# Install unzip and zip for plugin manipulation
RUN dnf update -y && dnf install -y tar gzip shadow-utils which unzip zip && dnf clean all

# Create an opensearch user, group
# OpenShift compatibility: Add user to root group (GID 0) for random UID support
RUN groupadd -g $GID opensearch && \
    adduser -u $UID -g $GID -G 0 -d $OPENSEARCH_HOME opensearch

# Copy from Stage0
COPY --from=linux_stage_0 --chown=$UID:0 $OPENSEARCH_HOME $OPENSEARCH_HOME
WORKDIR $OPENSEARCH_HOME

# Set $JAVA_HOME
RUN echo "export JAVA_HOME=$OPENSEARCH_HOME/jdk" >> /etc/profile.d/java_home.sh && \
    echo "export PATH=\$PATH:\$JAVA_HOME/bin" >> /etc/profile.d/java_home.sh && \
    ls -l $OPENSEARCH_HOME

ENV JAVA_HOME=$OPENSEARCH_HOME/jdk
ENV PATH=$PATH:$JAVA_HOME/bin:$OPENSEARCH_HOME/bin

# Add k-NN lib directory to library loading path variable
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$OPENSEARCH_HOME/plugins/opensearch-knn/lib"

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

# Copy local plugin snapshots from build context
COPY opensearch-knn-3.5.0.0.zip opensearch-neural-search-3.5.0.0-SNAPSHOT.zip opensearch-ml-3.5.0.0-SNAPSHOT.zip opensearch-security-3.5.0.0.zip opensearch-cross-cluster-replication-3.5.0.0-SNAPSHOT.zip opensearch-alerting-3.5.0.0-SNAPSHOT.zip opensearch-job-scheduler-3.5.0.0-SNAPSHOT.zip ./

# Extract inner security zip and fix jar hell conflicts in security, ML and neural-search plugins
RUN echo "Extracting security plugin from wrapper zip..." && \
    ls -lh opensearch-security-3.5.0.0.zip && \
    echo "Fixing jar hell conflicts in security, ML and neural-search plugins..." && \
    mkdir -p security-temp ml-temp neural-temp && \
    unzip -q opensearch-security-3.5.0.0.zip -d security-temp && \
    find security-temp -name "bc*.jar" -delete && \
    (cd security-temp && zip -qr ../opensearch-security-3.5.0.0-fixed.zip .) && \
    unzip -q opensearch-ml-3.5.0.0-SNAPSHOT.zip -d ml-temp && \
    find ml-temp -name "bc-fips*.jar" -delete && \
    (cd ml-temp && zip -qr ../opensearch-ml-3.5.0.0-SNAPSHOT-fixed.zip .) && \
    unzip -q opensearch-neural-search-3.5.0.0-SNAPSHOT.zip -d neural-temp && \
    find neural-temp -name "bc-fips*.jar" -delete && \
    (cd neural-temp && zip -qr ../opensearch-neural-search-3.5.0.0-SNAPSHOT-fixed.zip .) && \
    rm -rf security-temp ml-temp neural-temp && \
    ls -lh opensearch-*-fixed.zip && \
    echo "Plugins ready for installation"

RUN --mount=type=secret,id=artifactory_user_secret,uid=$UID \
    --mount=type=secret,id=artifactory_token_secret,uid=$UID \
    export artifactory_user=$(cat /run/secrets/artifactory_user_secret) && \
    export artifactory_token=$(cat /run/secrets/artifactory_token_secret) && \
    echo "Downloading plugins from JFrog..." && \
    curl -f -S -s -u ${artifactory_user}:${artifactory_token} -o opensearch-index-management-3.5.0.0.zip -L https://na.artifactory.swg-devops.com/artifactory/hyc-cpd-skywalker-team-lakehouse-on-prem-wxd-maven-local/power/opensearch/opensearch-index-management/opensearch-index-management-040626-3.5.0.0.zip && \
    curl -f -S -s -u ${artifactory_user}:${artifactory_token} -o opensearch-ltr-3.5.0.0.zip -L https://na.artifactory.swg-devops.com/artifactory/hyc-cpd-skywalker-team-lakehouse-on-prem-wxd-maven-local/power/opensearch/opensearch-ltr/opensearch-ltr-040626-3.5.0.0.zip && \
    curl -f -S -s -u ${artifactory_user}:${artifactory_token} -o opensearch-observability-3.5.0.0.zip -L https://na.artifactory.swg-devops.com/artifactory/hyc-cpd-skywalker-team-lakehouse-on-prem-wxd-maven-local/power/opensearch/opensearch-observability/opensearch-observability-040626-3.5.0.0.zip && \
    curl -f -S -s -u ${artifactory_user}:${artifactory_token} -o opensearch-reports-scheduler-3.5.0.0.zip -L https://na.artifactory.swg-devops.com/artifactory/hyc-cpd-skywalker-team-lakehouse-on-prem-wxd-maven-local/power/opensearch/opensearch-reports-scheduler/opensearch-reports-scheduler-040626-3.5.0.0.zip && \
    curl -f -S -s -u ${artifactory_user}:${artifactory_token} -o opensearch-query-insights-3.5.0.0.zip -L https://na.artifactory.swg-devops.com/artifactory/hyc-cpd-skywalker-team-lakehouse-on-prem-wxd-maven-local/power/opensearch/opensearch-query-insights/query-insights-040726-3.5.0.0.zip && \
    echo "Installing plugins..." && \
    echo y | opensearch-plugin install file://`pwd`/opensearch-security-3.5.0.0-fixed.zip && \
    echo y | opensearch-plugin install file://`pwd`/opensearch-job-scheduler-3.5.0.0-SNAPSHOT.zip && \
    echo y | opensearch-plugin install file://`pwd`/opensearch-index-management-3.5.0.0.zip && \
    echo y | opensearch-plugin install file://`pwd`/opensearch-ltr-3.5.0.0.zip && \
    echo y | opensearch-plugin install file://`pwd`/opensearch-observability-3.5.0.0.zip && \
    echo y | opensearch-plugin install file://`pwd`/opensearch-reports-scheduler-3.5.0.0.zip && \
    echo y | opensearch-plugin install file://`pwd`/opensearch-cross-cluster-replication-3.5.0.0-SNAPSHOT.zip && \
    echo y | opensearch-plugin install file://`pwd`/opensearch-alerting-3.5.0.0-SNAPSHOT.zip && \
    echo y | opensearch-plugin install file://`pwd`/opensearch-query-insights-3.5.0.0.zip && \
    echo y | opensearch-plugin install file://`pwd`/opensearch-knn-3.5.0.0.zip && \
    echo y | opensearch-plugin install file://`pwd`/opensearch-ml-3.5.0.0-SNAPSHOT-fixed.zip && \
    echo y | opensearch-plugin install file://`pwd`/opensearch-neural-search-3.5.0.0-SNAPSHOT-fixed.zip

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
  org.label-schema.build-date="$BUILD_DATE" \
  "DOCKERFILE"="https://github.com/opensearch-project/opensearch-build/blob/main/docker/release/dockerfiles/opensearch.al2.dockerfile"

# CMD to run
ENTRYPOINT ["./opensearch-docker-entrypoint.sh"]
CMD ["opensearch"]
