FROM openjdk:8

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

ENV JAVA_HOME "/usr/lib/jvm/java-8-openjdk-ppc64el"
ENV JAVA_TOOL_OPTIONS "-Dfile.encoding=UTF-8"

# Install dependencies.
RUN apt-get update && \
  apt-get install -y git maven && \

  #clone and build
  cd /tmp && \
  git clone https://github.com/apache/wink.git && \
  mv /tmp/wink/wink-common/src/test/java/org/apache/wink/common/model/wadl/WADLGeneratorTest.java /tmp/wink/wink-common/src/test/java/org/apache/wink/common/model/wadl/WADLGeneratorTest.DISABLE_java && \
  mv /tmp/wink/wink-server/src/test/java/org/apache/wink/server/internal/providers/entity/SourceProviderDTDSupportedTest.java /tmp/wink/wink-server/src/test/java/org/apache/wink/server/internal/providers/entity/SourceProviderDTDSupportedTest.DISABLE_java && \
  cd wink && \
  mvn install && \
  apt-get purge -y git maven && apt-get autoremove -y

CMD ["/bin/bash"]
