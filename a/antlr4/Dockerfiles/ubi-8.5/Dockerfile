FROM registry.access.redhat.com/ubi8 

WORKDIR /opt/antlr4

ARG PACKAGE_VERSION="4.11.1"
ARG MAVEN_OPTS="-Xmx1G"

ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-11.0.17.0.8-2.el8_6.ppc64le
ENV M2_HOME=/usr/local/maven
ENV PATH=$PATH:$M2_HOME/bin


RUN yum install -y git wget \
	&& yum install -y java-11-openjdk-devel 
	
RUN wget https://archive.apache.org/dist/maven/maven-3/3.8.5/binaries/apache-maven-3.8.5-bin.tar.gz \
	&& tar -C /usr/local/ -xzvf apache-maven-3.8.5-bin.tar.gz \
	&& rm -rf tar xzvf apache-maven-3.8.5-bin.tar.gz \
	&& mv /usr/local/apache-maven-3.8.5 /usr/local/maven 

RUN git clone https://github.com/antlr/antlr4.git \
    && cd antlr4 \
    && git checkout $PACKAGE_VERSION \
    && mvn clean --projects tool --also-make \
    && mvn -DskipTests install --projects tool --also-make \
    && mv tool/target/antlr4-*-complete.jar antlr4-tool.jar \
	&& cp antlr4-tool.jar /usr/local/lib/antlr4-tool.jar

ARG user=appuser
ARG group=appuser
ARG uid=1000
ARG gid=1000

RUN adduser \
    --disabled-login \
    --comment "" \
    --home-dir "$(pwd)" \
    --no-create-home \
    --uid "${uid}" \
    "${user}"

WORKDIR /work
ENTRYPOINT ["java", "-Xmx500M", "-cp", "/usr/local/lib/antlr4-tool.jar", "org.antlr.v4.Tool"]