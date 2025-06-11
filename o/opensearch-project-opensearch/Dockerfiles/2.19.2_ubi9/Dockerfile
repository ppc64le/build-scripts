#Copyright OpenSearch Contributors
# SPDX-License-Identifier: Apache-2.0
#
# Dockerfile for building an OpenSearch image.
# It assumes that the working directory contains these files: an OpenSearch tarball (opensearch.tgz), log4j2.properties, opensearch.yml, opensearch-docker-entrypoint.sh, opensearch-onetime-setup.sh.
# Build arguments:
#   VERSION: Required. Used to label the image.
#   BUILD_DATE: Required. Used to label the image. Should be in the form 'yyyy-mm-ddThh:mm:ssZ', i.e. a date-time from https://tools.ietf.org/html/rfc3339. The timestamp must be in UTC.
#   UID: Optional. Specify the opensearch userid. Defaults to 1000.
#   GID: Optional. Specify the opensearch groupid. Defaults to 1000.
#   OPENSEARCH_HOME: Optional. Specify the opensearch root directory. Defaults to /usr/share/opensearch.
#
# Multi-stage build:
#   1. Tarball Builder       - Builds OpenSearch tarball with k-NN & Performance Analyzer plugins
#   2. Runtime Preparer      - Extracts and configures OpenSearch for container runtime
#   3. Final Runtime Image   - Produces production-ready container image
###############################################################################

# ------------------------------------------------------------------------------
# Global Build Arguments (shared across stages)
# ------------------------------------------------------------------------------
ARG VERSION=2.19.2
ARG ARCH=ppc64le

# ------------------------------------------------------------------------------
# Stage 1: Tarball Builder - Build OpenSearch and custom plugins
# ------------------------------------------------------------------------------
FROM registry.access.redhat.com/ubi9/ubi:latest AS tarball_builder

ARG VERSION
ARG PLUGIN_VERSION=${VERSION}.0
ARG ARCH
ARG KNN_COMMITID="1b57a2a9a4e0f6993dedcb545a97c710065631eb"
ARG PERFORMANCE_ANALYZER_COMMITID="f743c9c08a7b383d86d9f99abe2094885e3872ee"
ARG OPENSEARCH-BUILD-PATCH="https://raw.githubusercontent.com/ppc64le/build-scripts/master/o/opensearch-project-opensearch/Dockerfiles/${VERSION}_ubi9/opensearch-build_${VERSION}.patch"
ARG OPENSEARCH-SKILLS-PATCH="https://raw.githubusercontent.com/ppc64le/build-scripts/master/o/opensearch-project-opensearch/Dockerfiles/${VERSION}_ubi9/opensearch-skills_${PLUGIN_VERSION}.patch"

# Install build dependencies
RUN yum update -y && \
    yum install -y \
        git wget sudo patch unzip make cmake gcc gcc-c++ perl \
        python3 python3-devel python3-pip \
        java-17-openjdk-devel && \
    yum clean all

# Install pipenv and yq
RUN python3 -m pip install pipenv && \
    wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_ppc64le && \
    chmod +x /usr/local/bin/yq

# Create non-root builder user
RUN useradd -m -s /bin/bash builder && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER builder
WORKDIR /home/builder

# Download required plugin patches and build scripts
RUN wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/o/opensearch-project-k-nn/k-NN-faiss-${PLUGIN_VERSION}.patch && \
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/o/opensearch-project-k-nn/k-NN-nmslib-${PLUGIN_VERSION}.patch && \
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/o/opensearch-project-k-nn/opensearch-project-k-NN_${PLUGIN_VERSION}_ubi_9.3.sh && \
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/o/opensearch-project-performance-analyzer/opensearch-project-performance-analyzer_${PLUGIN_VERSION}_ubi_9.3.sh && \
    chmod +x *.sh

# Build k-NN and Performance Analyzer plugins
RUN ./opensearch-project-k-NN_${PLUGIN_VERSION}_ubi_9.3.sh --skip-tests
RUN ./opensearch-project-performance-analyzer_${PLUGIN_VERSION}_ubi_9.3.sh --skip-tests

RUN git clone https://github.com/opensearch-project/skills.git && \
    cd skills && git checkout $PLUGIN_VERSION && \
    wget ${OPENSEARCH-SKILLS-PATCH} && \
    git apply ${OPENSEARCH-SKILLS-PATCH##*/} && \
    ./gradlew assemble

# Clone OpenSearch build repo and patch architecture support
RUN git clone https://github.com/opensearch-project/opensearch-build.git && \
    cd opensearch-build && git checkout $VERSION && \
    wget ${OPENSEARCH-BUILD-PATCH} && \
    git apply ${OPENSEARCH-BUILD-PATCH##*/}

# Build OpenSearch tarball
WORKDIR /home/builder/opensearch-build
RUN ./build.sh manifests/$VERSION/opensearch-$VERSION.yml \
        --platform linux \
        --architecture $ARCH \
        --distribution tar \
        --snapshot \
        --continue-on-error

WORKDIR /home/builder/opensearch-build
# Add custom plugins to the manifest
RUN cp /home/builder/k-NN/build/distributions/opensearch-knn-${PLUGIN_VERSION}-SNAPSHOT.zip tar/builds/opensearch/plugins/
RUN cp /home/builder/performance-analyzer/build/distributions/opensearch-performance-analyzer-${PLUGIN_VERSION}-SNAPSHOT.zip tar/builds/opensearch/plugins/
RUN cp /home/builder/skills/build/distributions/opensearch-skills-${PLUGIN_VERSION}-SNAPSHOT.zip tar/builds/opensearch/plugins/

RUN yq eval -i ".components = ( [.components[] | select(.name != \"neural-search\")] + [{\"name\": \"k-NN\", \"repository\": \"https://github.com/opensearch-project/k-NN.git\", \"ref\": \"tags/${PLUGIN_VERSION}\", \"commit_id\": \"${KNN_COMMITID}\", \"artifacts\": {\"maven\": [], \"plugins\": [\"plugins/opensearch-knn-${PLUGIN_VERSION}-SNAPSHOT.zip\"]}, \"version\": \"${PLUGIN_VERSION}-SNAPSHOT\"}] + [.components[] | select(.name == \"neural-search\")])" tar/builds/opensearch/manifest.yml

RUN grep -q 'name: performance-analyzer' tar/builds/opensearch/manifest.yml || \
    yq eval -i '.components |= . + [{"name":"performance-analyzer","repository":"https://github.com/opensearch-project/performance-analyzer.git","ref":"tags/$PLUGIN_VERSION","commit_id":"$PERFORMANCE_ANALYZER_COMMITID","artifacts":{"maven":[],"plugins":["plugins/opensearch-performance-analyzer-$PLUGIN_VERSION-SNAPSHOT.zip"]},"version":"$PLUGIN_VERSION-SNAPSHOT"}]' tar/builds/opensearch/manifest.yml

RUN ./assemble.sh tar/builds/opensearch/manifest.yml   

# ------------------------------------------------------------------------------
# Stage 2: Runtime Preparation - Extract and configure OpenSearch runtime
# ------------------------------------------------------------------------------
FROM registry.access.redhat.com/ubi9/ubi:latest AS linux_stage_0

ARG UID=1000
ARG GID=1000
ARG VERSION
ARG ARCH
ARG TEMP_DIR=/tmp/opensearch
ARG OPENSEARCH_HOME=/usr/share/opensearch
ARG OPENSEARCH_PATH_CONF=$OPENSEARCH_HOME/config
ARG SECURITY_PLUGIN_DIR=$OPENSEARCH_HOME/plugins/opensearch-security
ARG PERFORMANCE_ANALYZER_PLUGIN_CONFIG_DIR=$OPENSEARCH_PATH_CONF/opensearch-performance-analyzer

# Update packages
# Install the tools we need: tar and gzip to unpack the OpenSearch tarball, and shadow-utils to give us `groupadd` and `useradd`.
# Install which to allow running of securityadmin.sh
RUN yum update -y && yum install -y tar gzip shadow-utils which wget && yum clean all

# Create an opensearch user, group, and directory
RUN groupadd -g $GID opensearch && \
    adduser -u $UID -g $GID -d $OPENSEARCH_HOME opensearch && \
    mkdir $TEMP_DIR

RUN mkdir -p /opt/libs && cd /opt/libs && \
    wget -q https://repo1.maven.org/maven2/commons-beanutils/commons-beanutils/1.11.0/commons-beanutils-1.11.0.jar && \
    wget -q https://repo1.maven.org/maven2/org/apache/httpcomponents/client5/httpclient5/5.4.3/httpclient5-5.4.3.jar

# Prepare working directory
# Copy artifacts and configurations to corresponding directories
COPY --from=tarball_builder /home/builder/opensearch-build/tar/dist/opensearch/opensearch-$VERSION-SNAPSHOT-linux-$ARCH.tar.gz $TEMP_DIR/opensearch-$ARCH.tgz
COPY --from=tarball_builder /home/builder/opensearch-build/docker/release/config/opensearch/*.sh $TEMP_DIR/
COPY --from=tarball_builder /home/builder/opensearch-build/docker/release/config/opensearch/*.properties $TEMP_DIR/
COPY --from=tarball_builder /home/builder/opensearch-build/config/opensearch.yml $TEMP_DIR/
COPY --from=tarball_builder /home/builder/opensearch-build/scripts/opensearch-onetime-setup.sh $TEMP_DIR/
COPY * $TEMP_DIR/
RUN chmod +x $TEMP_DIR/*.sh

RUN ls -l $TEMP_DIR && \
    tar -xzpf /tmp/opensearch/opensearch-`uname -p`.tgz -C $OPENSEARCH_HOME --strip-components=1 && \
    # ✅ Replace vulnerable JARs
    find $OPENSEARCH_HOME/plugins -name "commons-beanutils-1.9.4.jar" -exec rm -v {} \; && \
    cp -v /opt/libs/commons-beanutils-1.11.0.jar $OPENSEARCH_HOME/plugins/opensearch-alerting/ && \
    cp -v /opt/libs/commons-beanutils-1.11.0.jar $OPENSEARCH_HOME/plugins/opensearch-ml/ && \
    cp -v /opt/libs/commons-beanutils-1.11.0.jar $OPENSEARCH_HOME/plugins/opensearch-sql/ && \

    find $OPENSEARCH_HOME/plugins/opensearch-ml -name "httpclient5-5.4.1.jar" -exec rm -v {} \; && \
    cp -v /opt/libs/httpclient5-5.4.3.jar $OPENSEARCH_HOME/plugins/opensearch-ml/ && \
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

# =============================================================================
# Stage 4: Final Image
# =============================================================================
# Copy working directory to the actual release docker images
FROM registry.access.redhat.com/ubi9/ubi:latest

ARG UID=1000
ARG GID=1000
ARG OPENSEARCH_HOME=/usr/share/opensearch

# Update packages
# Install the tools we need: tar and gzip to unpack the OpenSearch tarball, and shadow-utils to give us `groupadd` and `useradd`.
# Install which to allow running of securityadmin.sh
RUN yum update -y && yum install -y tar gzip shadow-utils which && yum clean all

# Create an opensearch user, group
RUN groupadd -g $GID opensearch && \
    adduser -u $UID -g $GID -d $OPENSEARCH_HOME opensearch

# Copy from Stage0
COPY --from=linux_stage_0 --chown=$UID:$GID $OPENSEARCH_HOME $OPENSEARCH_HOME
WORKDIR $OPENSEARCH_HOME

# Set $JAVA_HOME
RUN echo "export JAVA_HOME=$OPENSEARCH_HOME/jdk" >> /etc/profile.d/java_home.sh && \
    echo "export PATH=\$PATH:\$JAVA_HOME/bin" >> /etc/profile.d/java_home.sh

ENV JAVA_HOME=$OPENSEARCH_HOME/jdk
ENV PATH=$PATH:$JAVA_HOME/bin:$OPENSEARCH_HOME/bin

# Add k-NN lib directory to library loading path variable
ENV LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$OPENSEARCH_HOME/plugins/opensearch-knn/lib"

# Change user
USER $UID

# Setup OpenSearch
# Disable security demo installation during image build, and allow user to disable during startup of the container
# Enable security plugin during image build, and allow user to disable during startup of the container
ARG DISABLE_INSTALL_DEMO_CONFIG=true
ARG DISABLE_SECURITY_PLUGIN=false
RUN ./opensearch-onetime-setup.sh

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
