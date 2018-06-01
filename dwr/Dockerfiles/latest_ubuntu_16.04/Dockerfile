FROM ppc64le/openjdk:8-jdk

ENV JAVA_TOOL_OPTIONS -Dfile.encoding=ISO-8859-1
ENV JAVA_HOME /usr/lib/jvm/java-1.8.0-openjdk-ppc64el

RUN apt-get update && \
        apt-get install -y ant subversion && \
        svn co http://svn.directwebremoting.org/dwr/trunk dwr && \
        cd dwr && ant jar

CMD ["/bin/bash"]
