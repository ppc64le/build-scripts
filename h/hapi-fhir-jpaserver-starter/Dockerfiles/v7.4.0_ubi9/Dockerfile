FROM registry.access.redhat.com/ubi9/ubi:9.3 as build-hapi

WORKDIR /tmp

ARG PACKAGE_VERSION=image/v7.4.0

ARG OPENTELEMETRY_JAVA_AGENT_VERSION=1.17.0

RUN yum install -y git make wget gcc-c++ java-17-openjdk java-17-openjdk-devel java-17-openjdk-headless && \
    export JAVA_HOME=/usr/lib/jvm/java-17-openjdk && \
    export PATH=$PATH:$JAVA_HOME/bin && \
        wget https://archive.apache.org/dist/maven/maven-3/3.8.7/binaries/apache-maven-3.8.7-bin.tar.gz && \
        tar -zxf apache-maven-3.8.7-bin.tar.gz && \
        cp -R apache-maven-3.8.7 /usr/local && \
        ln -s /usr/local/apache-maven-3.8.7/bin/mvn /usr/bin/mvn && \
        git clone https://github.com/hapifhir/hapi-fhir-jpaserver-starter.git && \
        cd hapi-fhir-jpaserver-starter/ && \
        git checkout $PACKAGE_VERSION && \
        curl -LSsO https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v${OPENTELEMETRY_JAVA_AGENT_VERSION}/opentelemetry-javaagent.jar && \
        mvn -ntp dependency:go-offline && \
        mvn clean install -DskipTests -Djdk.lang.Process.launchMechanism=vfork

FROM build-hapi AS build-final

RUN cd hapi-fhir-jpaserver-starter/ && \
    mvn package spring-boot:repackage -Pboot
RUN mkdir /app && cp /tmp/hapi-fhir-jpaserver-starter/target/ROOT.war /app/main.war

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest as tomcat

RUN rm -rf /usr/local/tomcat/webapps/ROOT && \
    mkdir -p /usr/local/hapi/data/hapi/lucenefiles && \
    chmod 775 /usr/local/hapi/data/hapi/lucenefiles

USER root
RUN mkdir -p /target && chown -R 1001:1001 /target
USER 1001

COPY --from=build-hapi --chown=1001:1001 /tmp/hapi-fhir-jpaserver-starter/catalina.properties /usr/local/tomcat/conf/catalina.properties
COPY --from=build-hapi --chown=1001:1001 /tmp/hapi-fhir-jpaserver-starter/server.xml /usr/local/tomcat/conf/server.xml

COPY --from=build-hapi --chown=1001:1001 /tmp/hapi-fhir-jpaserver-starter/target/ROOT.war /usr/local/tomcat/webapps/ROOT.war
COPY --from=build-hapi --chown=1001:1001 /tmp/hapi-fhir-jpaserver-starter/opentelemetry-javaagent.jar /app

ENV ALLOW_EMPTY_PASSWORD=yes

FROM registry.access.redhat.com/ubi9/ubi-minimal as default

WORKDIR /app

COPY --from=build-final /app /app
COPY --from=build-hapi /tmp/hapi-fhir-jpaserver-starter/opentelemetry-javaagent.jar /app

RUN microdnf install -y java-17-openjdk-headless

ENTRYPOINT ["java", "--class-path", "/app/main.war", "-Dloader.path=main.war!/WEB-INF/classes/,main.war!/WEB-INF/,/app/extra-classes", "org.springframework.boot.loader.PropertiesLauncher", "app/main.war"]