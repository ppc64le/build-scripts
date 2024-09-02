
FROM docker.io/library/maven:3.9.2-eclipse-temurin-17-focal as build-hapi
WORKDIR /tmp

ARG PACKAGE_VERSION=image/v7.4.0

ARG OPENTELEMETRY_JAVA_AGENT_VERSION=1.17.0

RUN git clone https://github.com/hapifhir/hapi-fhir-jpaserver-starter.git && \
        cd hapi-fhir-jpaserver-starter/ && \
        git checkout $PACKAGE_VERSION && \
        curl -LSsO https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v${OPENTELEMETRY_JAVA_AGENT_VERSION}/opentelemetry-javaagent.jar && \
        mvn -ntp dependency:go-offline && \
        mvn clean install -DskipTests -Djdk.lang.Process.launchMechanism=vfork

FROM build-hapi AS build-final

RUN cd hapi-fhir-jpaserver-starter/ && \
    mvn package spring-boot:repackage -Pboot
RUN mkdir /app && cp /tmp/hapi-fhir-jpaserver-starter/target/ROOT.war /app/main.war

FROM docker.io/library/tomcat:9-jdk17-temurin-focal as tomcat

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

FROM eclipse-temurin:17.0.8.1_1-jdk-focal as default
WORKDIR /app

COPY --from=build-final /app /app
COPY --from=build-hapi /tmp/hapi-fhir-jpaserver-starter/opentelemetry-javaagent.jar /app


ENTRYPOINT ["java", "--class-path", "/app/main.war", "-Dloader.path=main.war!/WEB-INF/classes/,main.war!/WEB-INF/,/app/extra-classes", "org.springframework.boot.loader.PropertiesLauncher", "app/main.war"]
