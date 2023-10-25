FROM docker.io/library/maven:3.9.2-eclipse-temurin-17-focal as build-hapi
WORKDIR /tmp/hapi-fhir-jpaserver-starter

ARG OPENTELEMETRY_JAVA_AGENT_VERSION=1.17.0
RUN curl -LSsO https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v${OPENTELEMETRY_JAVA_AGENT_VERSION}/opentelemetry-javaagent.jar

COPY pom.xml .
COPY server.xml .
RUN mvn -ntp dependency:go-offline

COPY src/ /tmp/hapi-fhir-jpaserver-starter/src/
RUN mvn clean install -DskipTests -Djdk.lang.Process.launchMechanism=vfork

FROM build-hapi AS build-final
RUN mvn package spring-boot:repackage -Pboot
RUN mkdir /app && cp /tmp/hapi-fhir-jpaserver-starter/target/ROOT.war /app/main.war


FROM docker.io/library/tomcat:9-jdk17-temurin-focal as tomcat

RUN rm -rf /usr/local/tomcat/webapps/ROOT && \
    mkdir -p /usr/local/hapi/data/hapi/lucenefiles && \
    chmod 775 /usr/local/hapi/data/hapi/lucenefiles

USER root
RUN mkdir -p /target && chown -R 1001:1001 /target
USER 1001

COPY --chown=1001:1001 catalina.properties /usr/local/tomcat/conf/catalina.properties
COPY --chown=1001:1001 server.xml /usr/local/tomcat/conf/server.xml
COPY --from=build-hapi --chown=1001:1001 /tmp/hapi-fhir-jpaserver-starter/target/ROOT.war /usr/local/tomcat/webapps/ROOT.war
COPY --from=build-hapi --chown=1001:1001 /tmp/hapi-fhir-jpaserver-starter/opentelemetry-javaagent.jar /app

ENV ALLOW_EMPTY_PASSWORD=yes

FROM eclipse-temurin:17.0.8.1_1-jdk-focal as default
WORKDIR /app

COPY --from=build-final /app /app
COPY --from=build-hapi /tmp/hapi-fhir-jpaserver-starter/opentelemetry-javaagent.jar /app


ENTRYPOINT ["java", "--class-path", "/app/main.war", "-Dloader.path=main.war!/WEB-INF/classes/,main.war!/WEB-INF/,/app/extra-classes", "org.springframework.boot.loader.PropertiesLauncher", "app/main.war"]
