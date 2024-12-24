#Dockerfile for building Apache-kafka on ppc64le
FROM ppc64le/openjdk:8-jdk

MAINTAINER "Sarvesh Tamba <sarvesh.tamba@ibm.com>"

#Install Gradle 
RUN wdir=`pwd` && \
wget https://services.gradle.org/distributions/gradle-4.10.2-bin.zip && \
unzip gradle-4.10.2-bin.zip

#Set ENV variables
ENV PATH $PATH:$wdir/gradle-4.10.2/bin
ENV JAVA_HOME /usr/lib/jvm/java-1.8.0-openjdk-ppc64el
ENV JRE_HOME ${JAVA_HOME}/jre
ENV PATH ${JAVA_HOME}/bin:$PATH


#Build Apache-kafka 
RUN git clone https://github.com/apache/kafka && \
cd kafka && \
git checkout 2.1 && \
gradle clean && \
gradle && \
./gradlew jar && \
./gradlew releaseTarGz -x signArchives

CMD ["/bin/bash"]