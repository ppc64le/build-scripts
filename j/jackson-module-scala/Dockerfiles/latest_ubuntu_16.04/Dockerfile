FROM ppc64le/ubuntu:16.04
MAINTAINER "Atul Sowani <sowania@us.ibm.com>"

ENV JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-ppc64el
ENV JAVA7_HOME=$JAVA_HOME
ENV PATH=$PATH:$JAVA_HOME/bin

RUN apt-get update -y && \
    apt-get install -y bc apt-transport-https dirmngr wget git \
        openjdk-8-jdk software-properties-common && \
    wget http://dl.bintray.com/sbt/debian/sbt-0.13.6.deb && \
    update-ca-certificates -f && \
    dpkg -i sbt-0.13.6.deb && rm -f sbt-0.13.6.deb && \
    git clone https://github.com/FasterXML/jackson-module-scala.git && \
    cd $PWD/jackson-module-scala && \
    sbt compile && \
    sbt 'set resolvers += "Sonatype OSS Snapshots" at "https://oss.sonatype.org/content/repositories/snapshots"' test && \
    dpkg -r sbt-0.13.6 && \
    apt-get remove --purge -y bc apt-transport-https dirmngr wget git && \
    apt-get autoremove -y

CMD ["/bin/bash"]
