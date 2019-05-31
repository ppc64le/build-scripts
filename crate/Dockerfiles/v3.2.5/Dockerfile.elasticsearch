FROM ubuntu:18.04
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

ENV PATH /usr/share/elasticsearch/bin:$PATH
ENV JAVA_HOME /usr/share/jdk-11+28
ENV PATH $JAVA_HOME:$PATH
RUN groupadd --gid 1000 elasticsearch && useradd -u 1000 -g 1000 -m -d /usr/share/elasticsearch elasticsearch

WORKDIR /usr/share/elasticsearch

# Download and extract defined ES version.
ENV ELASTICSEARCH_VERSION 6.5.1

RUN apt-get update \
        && apt-get install maven wget git zip unzip  -y \
                --allow-unauthenticated \
                --no-install-recommends \

        # install openjdk11
        && wget https://github.com/AdoptOpenJDK/openjdk11-binaries/releases/download/jdk-11%2B28/OpenJDK11-jdk_ppc64le_linux_hotspot_11_28.tar.gz \
        && tar -C /usr/share/ -xzvf OpenJDK11-jdk_ppc64le_linux_hotspot_11_28.tar.gz \
        && rm -rf OpenJDK11-jdk_ppc64le_linux_hotspot_11_28.tar.gz \

        # build elasticsearch from source
        && git clone https://github.com/crate/elasticsearch.git \
        && cd elasticsearch && git checkout e418ad01646f32fd2b741246c1701d0eaa1a2383  \
        && sed -i '/ARCHITECTURES = Collections.unmodifiableMap(m);/ i \ \ \ \ \ \ \ \ m.put("ppc64le", new Arch(0xC0000015, 0xFFFFFFFF, 2, 189, 11, 362, 358));' server/src/main/java/org/elasticsearch/bootstrap/SystemCallFilter.java \
        && sed -i '$ d' distribution/src/config/jvm.options \
        && echo "xpack.ml.enabled: false" >> distribution/src/config/elasticsearch.yml \
        && echo "cluster.name: \"docker-cluster\""  >>  distribution/src/config/elasticsearch.yml \
        && echo "discovery.zen.minimum_master_nodes: 1" >> distribution/src/config/elasticsearch.yml \
        && echo "network.host: 0.0.0.0" >>  distribution/src/config/elasticsearch.yml \
        && ./gradlew assemble #--refresh-dependencies

        # copy tar file and to delete source code
RUN     cp elasticsearch/distribution/archives/tar/build/distributions/elasticsearch-$ELASTICSEARCH_VERSION-SNAPSHOT.tar.gz . \
        && rm -rf elasticsearch \
        && tar -xf elasticsearch-${ELASTICSEARCH_VERSION}-SNAPSHOT.tar.gz \
        && mv /usr/share/elasticsearch/elasticsearch-${ELASTICSEARCH_VERSION}-SNAPSHOT/* /usr/share/elasticsearch \
        && rm -rf /usr/share/elasticsearch/elasticsearch-${ELASTICSEARCH_VERSION}-SNAPSHOT  \

        # download jna explicitly
        && wget http://repo1.maven.org/maven2/net/java/dev/jna/jna/4.5.1/jna-4.5.1.jar \
        && mv jna-4.5.1.jar lib/ \

        # remove dependencies
        && apt-get purge --auto-remove maven wget git zip unzip -y \
        && chown -R elasticsearch:elasticsearch . \
        && rm -rf elasticsearch-$ELASTICSEARCH_VERSION-SNAPSHOT.tar.gz \
        && chown elasticsearch:elasticsearch -R /usr/share/elasticsearch


USER elasticsearch
EXPOSE 9200 9300
ENV PATH /usr/share/elasticsearch/bin:$PATH
CMD ["elasticsearch"]

