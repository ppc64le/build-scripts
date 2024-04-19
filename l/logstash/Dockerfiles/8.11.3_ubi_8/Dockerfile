
#Stage-1 builds logstash tarball for ppc64le
FROM registry.access.redhat.com/ubi8/ubi:8.9 as build 

MAINTAINER "Sapana Khemkar <Sapana.Khemkar@ibm.com>"

ARG PACKAGE_VERSION=v8.11.3
ARG PATCH=https://raw.githubusercontent.com/ppc64le/build-scripts/master/l/logstash/assemble-tar-withoutjdk.patch
ENV PACKAGE_NAME=logstash
ENV PACKAGE_URL=https://github.com/elastic/logstash.git

#Install dependencies
RUN yum -y update && yum install -y git procps yum-utils wget ncurses make gcc-c++ libffi-devel java-17-openjdk java-17-openjdk-devel java-17-openjdk-headless

#Install bison and readline-devel
RUN yum-config-manager --add-repo http://rpmfind.net/linux/centos/8-stream/AppStream/ppc64le/os/ && \
    yum-config-manager --add-repo http://rpmfind.net/linux/centos/8-stream/PowerTools/ppc64le/os/ &&\
    yum-config-manager --add-repo http://rpmfind.net/linux/centos/8-stream/BaseOS/ppc64le/os/ &&\
    wget https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official &&\
    mv RPM-GPG-KEY-CentOS-Official /etc/pki/rpm-gpg/. && \
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Official &&\
    yum install -y bison readline-devel


#Install dependencies
#RUN yum install -y make wget git sudo curl zip unzip tar pkg-config openssl-devel gcc-toolset-11-toolchain

#set JAVA_HOME
#ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-17.0.9.0.9-2.el8.ppc64le/
#ENV PATH=/usr/lib/jvm/java-17-openjdk-17.0.9.0.9-2.el8.ppc64le/bin:$PATH


#Get logstash source to build
WORKDIR /tmp
#COPY assemble-tar-withoutjdk.patch /tmp/assemble-tar-withoutjdk.patch 
RUN git clone https://github.com/elastic/logstash &&\
    cd ${PACKAGE_NAME} && \
    git checkout $PACKAGE_VERSION && \
    wget $PATCH && \
    git apply ${PATCH##*/}  

#install rvm and ruby (ruby version should be same as in .ruby_version in logstash
RUN curl -sSL https://rvm.io/mpapis.asc | gpg2 --import - && \
    curl -sSL https://rvm.io/pkuczynski.asc | gpg2 --import -
RUN curl -L https://get.rvm.io | bash -s stable

RUN /bin/bash -l -c "bash /etc/profile.d/rvm.sh && echo $PATH && rvm install $(cat /tmp/logstash/.ruby-version)"

RUN /bin/bash -l -c "gem install rake && \
    gem install bundler"
	
ENV OSS=true
ENV LOGSTASH_SOURCE=1
ENV LOGSTASH_PATH=/tmp/logstash

# build and generate tar
RUN cd ${PACKAGE_NAME} && \
    ./gradlew assembleTarDistributionWithoutJdk

# Stage-2 of multistage dockerfile to install logstash tarball
FROM registry.access.redhat.com/ubi8/ubi:8.9

#Install required dependencies
RUN yum install -y procps yum-utils ncurses wget

# Provide a non-root user to run the process.
RUN groupadd --gid 1000 logstash && \
    adduser --uid 1000 --gid 1000 \
       --home /usr/share/logstash --no-create-home \
      logstash
	  
#install adoptium java-17.0.9-openjdk
RUN \
	wget https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.9%2B9/OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.9_9.tar.gz &&\
	tar xzf OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.9_9.tar.gz -C /usr/share 
ENV PATH=/usr/share/jdk-17.0.9+9/bin:$PATH
ENV JAVA_HOME=/usr/share/jdk-17.0.9+9	

COPY --from=build /tmp/logstash/build/logstash-8.11.3-SNAPSHOT.tar.gz /tmp/logstash-8.11.3-SNAPSHOT.tar.gz

RUN tar zxf /tmp/logstash-8.11.3-SNAPSHOT.tar.gz  -C /usr/share && \
    mv /usr/share/logstash-* /usr/share/logstash && \
	chown --recursive logstash:logstash /usr/share/logstash/ && \
    chown -R logstash:root /usr/share/logstash && \
    chmod -R g=u /usr/share/logstash && \
    mkdir /licenses/ && \
    mv /usr/share/logstash/NOTICE.TXT /licenses/NOTICE.TXT && \
    mv /usr/share/logstash/LICENSE.txt /licenses/LICENSE.txt && \
	find /usr/share/logstash -type d -exec chmod g+s {} \; && \
	ln -s /usr/share/logstash /opt/logstash

WORKDIR /usr/share/logstash
ENV ELASTIC_CONTAINER true
ENV PATH=/usr/share/logstash/bin:$PATH

# Provide a minimal configuration, so that simple invocations will provide
# a good experience.
COPY config/pipelines.yml config/pipelines.yml
COPY config/logstash-full.yml config/logstash.yml
COPY config/log4j2.properties config/
COPY config/log4j2.file.properties config/
COPY pipeline/default.conf pipeline/logstash.conf
RUN chown --recursive logstash:root config/ pipeline/
# Ensure Logstash gets the correct locale by default.
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
COPY env2yaml/env2yaml /usr/local/bin/
# Place the startup wrapper script.
COPY bin/docker-entrypoint /usr/local/bin/
RUN chmod 0755 /usr/local/bin/docker-entrypoint

USER 1000

EXPOSE 9600 5044

LABEL  org.label-schema.schema-version="1.0" \
  org.label-schema.vendor="Elastic" \
  org.opencontainers.image.vendor="Elastic" \
  org.label-schema.name="logstash" \
  org.opencontainers.image.title="logstash" \
  org.label-schema.version="8.11.3" \
  org.opencontainers.image.version="8.11.3" \
  org.label-schema.url="https://www.elastic.co/products/logstash" \
  org.label-schema.vcs-url="https://github.com/elastic/logstash" \
  org.label-schema.license="Elastic License" \
  org.opencontainers.image.licenses="Elastic License" \
  org.opencontainers.image.description="Logstash is a free and open server-side data processing pipeline that ingests data from a multitude of sources, transforms it, and then sends it to your favorite 'stash.'" \
  org.label-schema.build-date=2023-12-05T12:30:34+00:00 \
org.opencontainers.image.created=2023-12-05T12:30:34+00:00

ENTRYPOINT ["/usr/local/bin/docker-entrypoint"]
