
################################################################################
# This Dockerfile was generated from the template at https://github.com/elastic/dockerfiles/blob/v7.6.0/elasticsearch/Dockerfile
#
# Beginning of multi stage Dockerfile
################################################################################

################################################################################
# Build stage 0 `builder`:
# Extract elasticsearch artifact
# Install required plugins
# Set gid=0 and make group perms==owner perms
################################################################################

ARG PACKAGE_VERSION=v7.6.0

FROM centos:7 AS builder

RUN for iter in {1..10}; do yum update --setopt=tsflags=nodocs -y &&     yum install --setopt=tsflags=nodocs -y maven wget sudo docker gzip git shadow-utils tar &&     yum clean all && exit_code=0 && break || exit_code=$? && echo "yum error: retry $iter in 10s" && sleep 10; done;     (exit $exit_code)

ENV PATH /usr/share/elasticsearch/bin:$PATH
ENV JAVA_HOME /usr/local/jdk-13.0.2+8/
ENV JAVA13_HOME /usr/local/jdk-13.0.2+8/
ENV PATH $PATH:/usr/local/jdk-13.0.2+8/bin/

RUN groupadd -g 1000 elasticsearch &&     adduser -u 1000 -g 1000 -d /usr/share/elasticsearch elasticsearch

WORKDIR /usr/share/elasticsearch

RUN cd /root && wget https://github.com/AdoptOpenJDK/openjdk13-binaries/releases/download/jdk13u-2020-02-24-07-25/OpenJDK13U-jdk_ppc64le_linux_hotspot_2020-02-24-07-25.tar.gz \
	&& tar -C /usr/local -xzf OpenJDK13U-jdk_ppc64le_linux_hotspot_2020-02-24-07-25.tar.gz \
	&& sudo ln -sf /usr/local/jdk-13.0.2+8/bin/java /usr/bin/ \
	&& cd /root && git clone https://github.com/elastic/elasticsearch.git \
	&& cd elasticsearch && git checkout $PACKAGE_VERSION \
	&& sed -i '/ARCHITECTURES = Collections.unmodifiableMap(m);/ i \ \ \ \ \ \ \ \ m.put("ppc64le", new Arch(0xC0000015, 0xFFFFFFFF, 2, 189, 11, 362, 358));' server/src/main/java/org/elasticsearch/bootstrap/SystemCallFilter.java \
	&& sed -i '$ d' distribution/src/config/jvm.options \
	&& echo "xpack.ml.enabled: false" >> distribution/src/config/elasticsearch.yml \
	&& echo "network.host: localhost" >>  distribution/src/config/elasticsearch.yml \
	&& sed -i '$ a\'"buildDeb.enabled=false \n buildOssDeb.enabled=false" ./distribution/packages/build.gradle \
	&& sed -i -e "s/import java.nio.file.Path/import java.nio.file.Path\n\/\/ Detecting the architecture\n String arch = System.getProperty('os.arch', '');/g" -e "s/archiveClassifier = 'linux-x86_64'/archiveClassifier = 'linux-'+ arch/g" distribution/archives/build.gradle \
	&& sed -i -e "s/apply plugin: 'elasticsearch.test.fixtures'/apply plugin: 'elasticsearch.test.fixtures'\n\/\/ Detecting the architecture\nString arch = System.getProperty('os.arch', '');/g" -e "s/final String classifier = 'linux-x86_64'/final String classifier = 'linux-' + arch/g" distribution/docker/build.gradle \
	&& sed -i 's/if (project.file("\/proc\/cpuinfo").exists()) {/if ("ppc64le".equals(System.getProperty("os.arch"))) { \n  \/\/ Ask ppc64le to count physical CPUs for us \n ByteArrayOutputStream stdout = new ByteArrayOutputStream(); \n \t project.exec{  \n\t executable "nproc" \n\t args "--all\"  \n\t standardOutput = stdout\n}\n return Integer.parseInt(stdout.toString("UTF-8").trim())\n } else if (project.file("\/proc\/cpuinfo").exists()) {/g' buildSrc/src/main/groovy/org/elasticsearch/gradle/BuildPlugin.groovy \
	&& ./gradlew -p distribution/archives/linux-tar assemble --parallel 

RUN tar zxf /root/elasticsearch/distribution/archives/linux-tar/build/distributions/elasticsearch-*-SNAPSHOT-linux-ppc64le.tar.gz --strip-components=1
RUN grep ES_DISTRIBUTION_TYPE=tar /usr/share/elasticsearch/bin/elasticsearch-env     && sed -i -e 's/ES_DISTRIBUTION_TYPE=tar/ES_DISTRIBUTION_TYPE=docker/' /usr/share/elasticsearch/bin/elasticsearch-env
RUN mkdir -p config data logs
RUN chmod 0775 config data logs
COPY config/elasticsearch.yml config/log4j2.properties config/
RUN chmod 0660 config/elasticsearch.yml config/log4j2.properties

################################################################################
# Build stage 1 (the actual elasticsearch image):
# Copy elasticsearch from stage 0
# Add entrypoint
################################################################################

FROM centos:7

ENV ELASTIC_CONTAINER true

RUN for iter in {1..10}; do yum update --setopt=tsflags=nodocs -y &&     yum install --setopt=tsflags=nodocs -y nc shadow-utils zip unzip wget &&     yum clean all && exit_code=0 && break || exit_code=$? && echo "yum error: retry $iter in 10s" && sleep 10; done;     (exit $exit_code)

RUN groupadd -g 1000 elasticsearch &&     adduser -u 1000 -g 1000 -G 0 -d /usr/share/elasticsearch elasticsearch &&     chmod 0775 /usr/share/elasticsearch &&     chgrp 0 /usr/share/elasticsearch

WORKDIR /usr/share/elasticsearch
COPY --from=builder --chown=1000:0 /usr/share/elasticsearch /usr/share/elasticsearch

# Replace OpenJDK's built-in CA certificate keystore with the one from the OS
# vendor. The latter is superior in several ways.
# REF: https://github.com/elastic/elasticsearch-docker/issues/171
RUN ln -sf /etc/pki/ca-trust/extracted/java/cacerts /usr/share/elasticsearch/jdk/lib/security/cacerts

ENV PATH /usr/share/elasticsearch/bin:$PATH
ENV JAVA_HOME /usr/local/jdk-13.0.2+8/
ENV JAVA13_HOME /usr/local/jdk-13.0.2+8/
ENV PATH $PATH:/usr/local/jdk-13.0.2+8/bin/

RUN cd /root && wget https://github.com/AdoptOpenJDK/openjdk13-binaries/releases/download/jdk13u-2020-02-24-07-25/OpenJDK13U-jdk_ppc64le_linux_hotspot_2020-02-24-07-25.tar.gz \
	&& tar -C /usr/local -xzf OpenJDK13U-jdk_ppc64le_linux_hotspot_2020-02-24-07-25.tar.gz \
	&& ln -sf /usr/local/jdk-13.0.2+8/bin/java /usr/bin/ \
	&& echo "bootstrap.system_call_filter: false" >> /usr/share/elasticsearch/config/elasticsearch.yml \
	&& echo "discovery.seed_hosts: []" >> /usr/share/elasticsearch/config/elasticsearch.yml \
	&& echo "xpack.ml.enabled: false" >> /usr/share/elasticsearch/config/elasticsearch.yml 

COPY --chown=1000:0 bin/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Openshift overrides USER and uses ones with randomly uid>1024 and gid=0
# Allow ENTRYPOINT (and ES) to run even with a different user
RUN chgrp 0 /usr/local/bin/docker-entrypoint.sh &&     chmod g=u /etc/passwd &&     chmod 0775 /usr/local/bin/docker-entrypoint.sh

EXPOSE 9200 9300

LABEL org.label-schema.build-date="2020-02-29T00:15:25.529771Z"   org.label-schema.license="Elastic-License"   org.label-schema.name="Elasticsearch"   org.label-schema.schema-version="1.0"   org.label-schema.url="https://www.elastic.co/products/elasticsearch"   org.label-schema.usage="https://www.elastic.co/guide/en/elasticsearch/reference/index.html"   org.label-schema.vcs-ref="aa751e09be0a5072e8570670309b1f12348f023b"   org.label-schema.vcs-url="https://github.com/elastic/elasticsearch"   org.label-schema.vendor="Elastic"   org.label-schema.version="7.6.1"   org.opencontainers.image.created="2020-02-29T00:15:25.529771Z"   org.opencontainers.image.documentation="https://www.elastic.co/guide/en/elasticsearch/reference/index.html"   org.opencontainers.image.licenses="Elastic-License"   org.opencontainers.image.revision="aa751e09be0a5072e8570670309b1f12348f023b"   org.opencontainers.image.source="https://github.com/elastic/elasticsearch"   org.opencontainers.image.title="Elasticsearch"   org.opencontainers.image.url="https://www.elastic.co/products/elasticsearch"   org.opencontainers.image.vendor="Elastic"   org.opencontainers.image.version="7.6.1"

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
# Dummy overridable parameter parsed by entrypoint
CMD ["eswrapper"]

################################################################################
# End of multi-stage Dockerfile
################################################################################

