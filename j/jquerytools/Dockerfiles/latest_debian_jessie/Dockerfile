# Dockerfile for jQuery Tools
FROM ppc64le/openjdk:8-jdk

MAINTAINER Kumar Abhinav

ENV DEBIAN_FRONTEND "noninteractive"
ENV ANT_HOME /apache-ant-1.9.8
ENV PATH $PATH:$ANT_HOME/bin

RUN apt-get update -y \ 
	&& apt-get install -y wget git \
	&& wget https://archive.apache.org/dist/ant/binaries/apache-ant-1.9.8-bin.tar.gz && tar -xvzf apache-ant-1.9.8-bin.tar.gz \
	&& cd /apache-ant-1.9.8/lib/ \
	&& wget http://central.maven.org/maven2/ant-contrib/ant-contrib/1.0b3/ant-contrib-1.0b3.jar \
	&& git clone https://github.com/jquerytools/jquerytools.git && cd jquerytools && ant 

WORKDIR /jquerytools/
CMD ["/bin/bash"]

