#Dockerfile for building Apache-kafka on ppc64le
FROM ppc64le/openjdk:8-jdk

#Install Gradle 
RUN wdir=`pwd` && \
wget https://services.gradle.org/distributions/gradle-4.1-bin.zip && \
unzip gradle-4.1-bin.zip

#Set ENV variables
ENV PATH $PATH:$wdir/gradle-4.1/bin
ENV JAVA_HOME /usr/lib/jvm/java-1.8.0-openjdk-ppc64el
ENV JRE_HOME ${JAVA_HOME}/jre
ENV PATH ${JAVA_HOME}/bin:$PATH


#Build Apache-kafka 
RUN git clone https://github.com/apache/kafka && \
cd kafka && \
git checkout 0.10.2.0 && \
gradle && \
gradle jar && \
rm -rf $wdir/gradle-4.1* 
