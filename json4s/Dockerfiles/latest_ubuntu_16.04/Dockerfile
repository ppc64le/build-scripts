FROM openjdk:8

MAINTAINER "Jay Joshi <joshija@us.ibm.com>"

ENV JAVA_HOME /usr/lib/jvm/java-1.8.0-openjdk-ppc64el
ENV PATH $PATH:$JAVA_HOME/bin
ENV TZ Australia/Canberra

RUN apt-get update -y && \
    apt-get install -y apt-transport-https git && \
    echo "deb https://dl.bintray.com/sbt/debian /" |  tee -a /etc/apt/sources.list.d/sbt.list && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 642AC823 && \
    apt-get update && \
    apt-get install -y sbt && \
    git clone https://github.com/json4s/json4s json4s/json4s && \
    cd json4s/json4s && \
    git remote update && \
    git fetch && \
    git checkout -qf FETCH_HEAD && \
    apt-get purge -y git && apt-get autoremove -y && \
    sbt 'set resolvers += "Sonatype OSS Snapshots" at "https://oss.sonatype.org/content/repositories/snapshots"' test

CMD ["/bin/bash"]
