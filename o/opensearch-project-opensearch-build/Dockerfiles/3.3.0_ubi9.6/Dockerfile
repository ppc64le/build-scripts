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
ARG VERSION=3.3.0.0
ARG ARCH=ppc64le

# ------------------------------------------------------------------------------
# Stage 1: Tarball Builder - Build OpenSearch and custom plugins
# ------------------------------------------------------------------------------
FROM registry.access.redhat.com/ubi9/ubi:latest AS tarball_builder

ARG VERSION
ARG PLUGIN_VERSION=3.3.0.0
ARG ARCH
ARG KNN_COMMITID="5ac20a50e927ccc15f7aab61d5a9c32a62efb66c"
ARG INDEX_MANAGEMENT_COMMITID="792edf88fb28ee86538d03edf6cf016497fcbe28"
ARG OBSERVABILITY_COMMITID="101a85a8706c535bdbe1707f73683e52adcc409c"
ARG REPORTS_COMMITID="7d0331a186fb38be8254454aa9fe0bbfc60fe79e"
ARG SEARCH_RELEVANCE_COMMITID="61d9a51c402c659bbecc5757eec015a6df41da7c"
ARG UBI_COMMITID="df39f8abc5ab82a00690b09c2c216be57b7ad16f"
ARG NEURAL_SEARCH_COMMITID="81f6c4788974ab8e86de2ce60003fdca2aa8b605"
ARG QUERY_INSIGHTS_COMMITID="cdf1f9f737433c0390deb189a615cc937a21158c"
Arg ML_COMMONS_COMMITID="2f717c0f3e81e6ffb514303f92beba9942a59a59"
Arg SKILLS_COMMITID="7ca2e227e835f100e663803e67d01eb9fc9cc3d7"
Arg FLOW_FRAMEWORK_COMMITID="32c6a7d9904e8cc6c5e0c88e238324ec731173c4"
Arg SECURITY_COMMITID="53429a5853085da5258add822f768d248f70e228"


# Install build dependencies
RUN yum update -y && \
    yum install -y \
        git wget sudo patch unzip make cmake gcc gcc-c++ perl openblas openblas-devel \
        python3 python3-devel python3-pip \
        java-17-openjdk-devel && \
    yum clean all

# Install pipenv and yq
RUN python3 -m pip install pipenv && \
    wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_ppc64le && \
    chmod +x /usr/local/bin/yq

RUN yum install -y java-21-openjdk java-21-openjdk-devel
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk
ENV PATH=$JAVA_HOME/bin:$PATH

# Create non-root test_user user
RUN useradd -m -s /bin/bash test_user && \
    echo "test_user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER test_user
WORKDIR /home/test_user
COPY ./opensearch-build.patch /home/test_user/opensearch-build.patch

# Download required plugin patches and build scripts
RUN wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/o/opensearch-project-k-nn/k-NN-faiss-${PLUGIN_VERSION}.patch && \
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/o/opensearch-project-k-nn/k-NN-nmslib-${PLUGIN_VERSION}.patch && \
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/o/opensearch-project-k-nn/k-NN-${PLUGIN_VERSION}.patch && \
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/master/o/opensearch-project-k-nn/opensearch-project-k-NN_${PLUGIN_VERSION}_ubi_9.6.sh && \
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/opensearch-project-index-management/index-management_${PLUGIN_VERSION}.patch && \
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/opensearch-project-index-management/opensearch-project-index-management_${PLUGIN_VERSION}_ubi_9.6.sh && \
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/opensearch-project-observability/observability_${PLUGIN_VERSION}.patch && \
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/opensearch-project-observability/opensearch-project-observability_${PLUGIN_VERSION}_ubi_9.6.sh && \
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/opensearch-project-reporting/reporting_${PLUGIN_VERSION}.patch && \
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/opensearch-project-reporting/opensearch-project-reporting_${PLUGIN_VERSION}_ubi_9.6.sh && \
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/opensearch-project-search-relevance/search-relevance_${PLUGIN_VERSION}_ubi9.6.sh && \
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/opensearch-project-ubi/opensearch-project-ubi_${PLUGIN_VERSION}_ubi_9.6.sh && \
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/opensearch-project-neural-search/neural-search_${PLUGIN_VERSION}.patch && \
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/opensearch-project-neural-search/neural-search_${PLUGIN_VERSION}_ubi9.6.sh && \
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/opensearch-project-security/opensearch-project-security_${PLUGIN_VERSION}.patch && \
    wget https://raw.githubusercontent.com/ppc64le/build-scripts/refs/heads/master/o/opensearch-project-security/security_${PLUGIN_VERSION}_ubi9.6.sh
RUN chmod +x *.sh

  
RUN sed -i 's|/home/tester|/home/test_user|g' *.sh
RUN chmod +x *.sh


# Build plugins 
RUN ./opensearch-project-k-NN_${PLUGIN_VERSION}_ubi_9.6.sh ${PLUGIN_VERSION} --skip-tests
RUN rm -rf OpenSearch  \
    && ./opensearch-project-index-management_${PLUGIN_VERSION}_ubi_9.6.sh ${PLUGIN_VERSION} --skip-tests
RUN rm -rf OpenSearch common-utils job-scheduler \
    && ./opensearch-project-observability_${PLUGIN_VERSION}_ubi_9.6.sh ${PLUGIN_VERSION} --skip-tests
RUN rm -rf OpenSearch common-utils \
    && ./opensearch-project-reporting_${PLUGIN_VERSION}_ubi_9.6.sh ${PLUGIN_VERSION} --skip-tests
Run sed -i 's/git checkout \$PACKAGE_VERSION/git checkout -f \$PACKAGE_VERSION/g' search-relevance_${PLUGIN_VERSION}_ubi9.6.sh
RUN rm -rf OpenSearch common-utils \
    && ./search-relevance_${PLUGIN_VERSION}_ubi9.6.sh ${PLUGIN_VERSION} --skip-tests
RUN rm -rf OpenSearch common-utils \
    && ./opensearch-project-ubi_${PLUGIN_VERSION}_ubi_9.6.sh ${PLUGIN_VERSION} --skip-tests

 

# Inject native libs into k-NN plugin zip (ppc64le fix)
RUN set -eux; \
    zipPath="/home/test_user/k-NN/build/distributions/opensearch-knn-${PLUGIN_VERSION}.zip"; \
    distributions="$(dirname "$zipPath")"; \
    libdir="$distributions/lib"; \
    \
    mkdir -p "$libdir"; \
    \
    echo "Copying JNI native libraries..."; \
    cp -v /home/test_user/k-NN/jni/release/*.so "$libdir/"; \
    \
    echo "Native libraries staged:"; \
    ls -l "$libdir"; \
    \
    echo "Updating plugin ZIP..."; \
    cd "$distributions"; \
    zip -ur "$(basename "$zipPath")" lib

# Clone OpenSearch build repo and patch architecture support
RUN git clone https://github.com/opensearch-project/opensearch-build.git && \
    cd opensearch-build && git checkout 3.3.0 && \
    git apply ../opensearch-build.patch

COPY ./query-insights-${PLUGIN_VERSION}-SNAPSHOT.zip     /home/test_user/query-insights-${PLUGIN_VERSION}-SNAPSHOT.zip
COPY ./opensearch-neural-search-${PLUGIN_VERSION}-SNAPSHOT.zip /home/test_user/opensearch-neural-search-${PLUGIN_VERSION}-SNAPSHOT.zip
COPY ./opensearch-ml-${PLUGIN_VERSION}-SNAPSHOT.zip  /home/test_user/opensearch-ml-${PLUGIN_VERSION}-SNAPSHOT.zip
COPY ./opensearch-flow-framework-${PLUGIN_VERSION}-SNAPSHOT.zip /home/test_user/opensearch-flow-framework-${PLUGIN_VERSION}-SNAPSHOT.zip
COPY ./opensearch-skills-${PLUGIN_VERSION}-SNAPSHOT.zip  /home/test_user/opensearch-skills-${PLUGIN_VERSION}-SNAPSHOT.zip
COPY ./opensearch-security-${PLUGIN_VERSION}-SNAPSHOT.zip /home/test_user/opensearch-security-${PLUGIN_VERSION}-SNAPSHOT.zip

# Build OpenSearch tarball
WORKDIR /home/test_user/opensearch-build
RUN ./build.sh manifests/3.3.0/opensearch-3.3.0.yml \
        --platform linux \
        --architecture $ARCH \
        --distribution tar \
        --snapshot \
        --continue-on-error

RUN rm -rf tar/builds/opensearch/plugins/opensearch-security-${PLUGIN_VERSION}-SNAPSHOT.zip
WORKDIR /home/test_user/opensearch-build

RUN ls tar/builds/opensearch/plugins/ 

# Add custom plugins to the manifest
RUN cp /home/test_user/opensearch-security-${PLUGIN_VERSION}-SNAPSHOT.zip tar/builds/opensearch/plugins/
RUN cp /home/test_user/opensearch-skills-${PLUGIN_VERSION}-SNAPSHOT.zip tar/builds/opensearch/plugins/
RUN cp /home/test_user/opensearch-flow-framework-${PLUGIN_VERSION}-SNAPSHOT.zip tar/builds/opensearch/plugins/
RUN cp /home/test_user/opensearch-neural-search-${PLUGIN_VERSION}-SNAPSHOT.zip  tar/builds/opensearch/plugins/
RUN cp /home/test_user/opensearch-ml-${PLUGIN_VERSION}-SNAPSHOT.zip  tar/builds/opensearch/plugins/
RUN cp /home/test_user/query-insights-${PLUGIN_VERSION}-SNAPSHOT.zip tar/builds/opensearch/plugins
RUN cp /home/test_user/k-NN/build/distributions/opensearch-knn-${PLUGIN_VERSION}*.zip tar/builds/opensearch/plugins/
RUN cp /home/test_user/index-management/build/distributions/opensearch-index-management-${PLUGIN_VERSION}-SNAPSHOT.zip tar/builds/opensearch/plugins/
RUN cp /home/test_user/observability/build/distributions/opensearch-observability-${PLUGIN_VERSION}.zip tar/builds/opensearch/plugins/
RUN cp /home/test_user/reporting/build/distributions/opensearch-reports-scheduler-${PLUGIN_VERSION}*.zip  tar/builds/opensearch/plugins/
RUN cp /home/test_user/search-relevance/build/distributions/opensearch-search-relevance-*.zip tar/builds/opensearch/plugins/
RUN cp /home/test_user/user-behavior-insights/build/distributions/opensearch-ubi-${PLUGIN_VERSION}-SNAPSHOT.zip tar/builds/opensearch/plugins/

RUN cd tar/builds/opensearch/plugins && \
    mv opensearch-knn-${PLUGIN_VERSION}.zip opensearch-knn-${PLUGIN_VERSION}-SNAPSHOT.zip && \
    mv opensearch-reports-scheduler-${PLUGIN_VERSION}.zip opensearch-reports-scheduler-${PLUGIN_VERSION}-SNAPSHOT.zip && \
    mv opensearch-observability-${PLUGIN_VERSION}.zip opensearch-observability-${PLUGIN_VERSION}-SNAPSHOT.zip && \
    mv opensearch-search-relevance-${PLUGIN_VERSION}.zip opensearch-search-relevance-${PLUGIN_VERSION}-SNAPSHOT.zip
        
RUN cd tar/builds/opensearch/plugins && \
    cp opensearch-ml-${PLUGIN_VERSION}-SNAPSHOT.zip ml-commons-${PLUGIN_VERSION}-SNAPSHOT.zip
RUN cd tar/builds/opensearch/plugins/ && \
    cp opensearch-skills-${PLUGIN_VERSION}-SNAPSHOT.zip  skills-${PLUGIN_VERSION}-SNAPSHOT.zip
RUN cd tar/builds/opensearch/plugins && \
    cp opensearch-flow-framework-${PLUGIN_VERSION}-SNAPSHOT.zip flow-framework-${PLUGIN_VERSION}-SNAPSHOT.zip
RUN cd tar/builds/opensearch/plugins && \
    cp opensearch-neural-search-${PLUGIN_VERSION}-SNAPSHOT.zip neural-search-${PLUGIN_VERSION}-SNAPSHOT.zip
RUN cd tar/builds/opensearch/plugins && \
    cp opensearch-security-${PLUGIN_VERSION}-SNAPSHOT.zip security-${PLUGIN_VERSION}-SNAPSHOT.zip        

RUN yq eval -i ".components = (  [.components[] | select(.name != \"neural-search\")] + [{\"name\": \"neural-search\", \"repository\": \"https://github.com/opensearch-project/neural-search.git\", \"ref\": \"tags/${PLUGIN_VERSION}\", \"commit_id\": \"${NEURAL_SEARCH_COMMITID}\", \"artifacts\": {\"maven\": [], \"plugins\": [\"plugins/neural-search-${PLUGIN_VERSION}-SNAPSHOT.zip\"]}, \"version\": \"${PLUGIN_VERSION}-SNAPSHOT\"}])" tar/builds/opensearch/manifest.yml
RUN yq eval -i ".components = (  [.components[] | select(.name != \"ml-commons\")] + [{\"name\": \"ml-commons\", \"repository\": \"https://github.com/opensearch-project/ml-commons.git\", \"ref\": \"tags/${PLUGIN_VERSION}\", \"commit_id\": \"${ML_COMMONS_COMMITID}\", \"artifacts\": {\"maven\": [], \"plugins\": [\"plugins/ml-commons-${PLUGIN_VERSION}-SNAPSHOT.zip\"]}, \"version\": \"${PLUGIN_VERSION}-SNAPSHOT\"}])" tar/builds/opensearch/manifest.yml
RUN yq eval -i ".components = (  [.components[] | select(.name != \"skills\")] + [{\"name\": \"skills\", \"repository\": \"https://github.com/opensearch-project/skills.git\", \"ref\": \"tags/${PLUGIN_VERSION}\", \"commit_id\": \"${SKILLS_COMMITID}\", \"artifacts\": {\"maven\": [], \"plugins\": [\"plugins/skills-${PLUGIN_VERSION}-SNAPSHOT.zip\"]}, \"version\": \"${PLUGIN_VERSION}-SNAPSHOT\"}])" tar/builds/opensearch/manifest.yml
RUN yq eval -i ".components = (  [.components[] | select(.name != \"flow-framework\")] + [{\"name\": \"flow-framework\", \"repository\": \"https://github.com/opensearch-project/flow-framework.git\", \"ref\": \"tags/${PLUGIN_VERSION}\", \"commit_id\": \"${FLOW_FRAMEWORK_COMMITID}\", \"artifacts\": {\"maven\": [], \"plugins\": [\"plugins/flow-framework-${PLUGIN_VERSION}-SNAPSHOT.zip\"]}, \"version\": \"${PLUGIN_VERSION}-SNAPSHOT\"}])" tar/builds/opensearch/manifest.yml
RUN yq eval -i ".components = (  [.components[] | select(.name != \"query-insights\")] + [{\"name\": \"query-insights\",\"repository\": \"https://github.com/opensearch-project/query-insights.git\",\"ref\": \"tags/${PLUGIN_VERSION}\",\"commit_id\": \"${QUERY_INSIGHTS_COMMITID}\",\"artifacts\": {\"maven\": [],\"plugins\": [\"plugins/query-insights-${PLUGIN_VERSION}-SNAPSHOT.zip\"]},\"version\": \"${PLUGIN_VERSION}-SNAPSHOT\"}])" tar/builds/opensearch/manifest.yml
RUN yq eval -i ".components = (  [.components[] | select(.name != \"neural-search\")] + [{\"name\": \"k-NN\", \"repository\": \"https://github.com/opensearch-project/k-NN.git\", \"ref\": \"tags/${PLUGIN_VERSION}\", \"commit_id\": \"${KNN_COMMITID}\", \"artifacts\": {\"maven\": [], \"plugins\": [\"plugins/opensearch-knn-${PLUGIN_VERSION}-SNAPSHOT.zip\"]}, \"version\": \"${PLUGIN_VERSION}-SNAPSHOT\"}] + [.components[] | select(.name == \"neural-search\")])" tar/builds/opensearch/manifest.yml
RUN yq eval -i ".components = (  [.components[] | select(.name != \"index-management\")]  +  [{    \"name\": \"index-management\",    \"repository\": \"https://github.com/opensearch-project/index-management.git\",    \"ref\": \"tags/${PLUGIN_VERSION}\",    \"commit_id\": \"${INDEX_MANAGEMENT_COMMITID}\",    \"artifacts\": {      \"maven\": [],      \"plugins\": [\"plugins/opensearch-index-management-${PLUGIN_VERSION}-SNAPSHOT.zip\"]    },    \"version\": \"${PLUGIN_VERSION}-SNAPSHOT\"  }])" tar/builds/opensearch/manifest.yml
RUN yq eval -i ".components = (  [.components[] | select(.name != \"opensearch-reports\")]  +  [{    \"name\": \"opensearch-reports\",    \"repository\": \"https://github.com/opensearch-project/reporting.git\",    \"ref\": \"tags/${PLUGIN_VERSION}\",    \"commit_id\": \"${REPORTS_COMMITID}\",    \"artifacts\": {      \"maven\": [],      \"plugins\": [\"plugins/opensearch-reports-scheduler-${PLUGIN_VERSION}-SNAPSHOT.zip\"]    },    \"version\": \"${PLUGIN_VERSION}-SNAPSHOT\"  }])" tar/builds/opensearch/manifest.yml
RUN yq eval -i ".components = (  [.components[] | select(.name != \"user-behavior-insights\")]  +  [{    \"name\": \"user-behavior-insights\",    \"repository\": \"https://github.com/opensearch-project/user-behavior-insights.git\",    \"ref\": \"tags/${PLUGIN_VERSION}\",    \"commit_id\": \"${UBI_COMMITID}\",    \"artifacts\": {      \"maven\": [],      \"plugins\": [\"plugins/opensearch-ubi-${PLUGIN_VERSION}-SNAPSHOT.zip\"]    },    \"version\": \"${PLUGIN_VERSION}-SNAPSHOT\"  }])" tar/builds/opensearch/manifest.yml
RUN yq eval -i ".components = (  [.components[] | select(.name != \"search-relevance\")]  +  [{    \"name\": \"search-relevance\",    \"repository\": \"https://github.com/opensearch-project/search-relevance.git\",    \"ref\": \"tags/${PLUGIN_VERSION}\",    \"commit_id\": \"${SEARCH_RELEVANCE_COMMITID}\",    \"artifacts\": {      \"maven\": [],      \"plugins\": [\"plugins/opensearch-search-relevance-${PLUGIN_VERSION}-SNAPSHOT.zip\"]    },    \"version\": \"${PLUGIN_VERSION}-SNAPSHOT\"  }])" tar/builds/opensearch/manifest.yml
RUN yq eval -i ".components = (  [.components[] | select(.name != \"opensearch-observability\")]  +  [{    \"name\": \"opensearch-observability\",    \"repository\": \"https://github.com/opensearch-project/observability.git\",    \"ref\": \"tags/${PLUGIN_VERSION}\",    \"commit_id\": \"${OBSERVABILITY_COMMITID}\",    \"artifacts\": {      \"maven\": [],      \"plugins\": [\"plugins/opensearch-observability-${PLUGIN_VERSION}-SNAPSHOT.zip\"]    },    \"version\": \"${PLUGIN_VERSION}-SNAPSHOT\"  }])" tar/builds/opensearch/manifest.yml


RUN rm -f tar/builds/opensearch/plugins/security-${PLUGIN_VERSION}-SNAPSHOT.zip

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
RUN yum update -y && yum install -y tar gzip shadow-utils which openblas openblas-devel && yum clean all

# Create an opensearch user, group, and directory
RUN groupadd -g $GID opensearch && \
    adduser -u $UID -g $GID -d $OPENSEARCH_HOME opensearch && \
    mkdir $TEMP_DIR

# Prepare working directory
# Copy artifacts and configurations to corresponding directories
COPY --from=tarball_builder /home/test_user/opensearch-build/tar/dist/opensearch/opensearch-3.3.0-SNAPSHOT-linux-$ARCH.tar.gz $TEMP_DIR/opensearch-$ARCH.tgz
COPY --from=tarball_builder /home/test_user/opensearch-build/docker/release/config/opensearch/*.sh $TEMP_DIR/
COPY --from=tarball_builder /home/test_user/opensearch-build/docker/release/config/opensearch/*.properties $TEMP_DIR/
COPY --from=tarball_builder /home/test_user/opensearch-build/config/opensearch.yml $TEMP_DIR/
COPY --from=tarball_builder /home/test_user/opensearch-build/scripts/opensearch-onetime-setup.sh $TEMP_DIR/
COPY * $TEMP_DIR/
RUN chmod +x $TEMP_DIR/*.sh

# Prepare working directory
# Copy artifacts and configurations to corresponding directories
RUN ls -l $TEMP_DIR && \
    tar -xzpf /tmp/opensearch/opensearch-`uname -p`.tgz -C $OPENSEARCH_HOME --strip-components=1 && \
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


########################### Stage 3 ########################
# Copy working directory to the actual release docker images
FROM registry.access.redhat.com/ubi9/ubi:latest

ARG UID=1000
ARG GID=1000
ARG OPENSEARCH_HOME=/usr/share/opensearch

# Update packages
# Install the tools we need: tar and gzip to unpack the OpenSearch tarball, and shadow-utils to give us `groupadd` and `useradd`.
# Install which to allow running of securityadmin.sh
RUN yum update -y && yum install -y tar gzip shadow-utils which openblas openblas-devel && yum clean all

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
