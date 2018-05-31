FROM openjdk:8-jdk
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

RUN apt-get update \
	&& apt-get install ant junit -y \
	&& wget https://sourceforge.net/projects/jsap/files/jsap/2.1/JSAP-2.1-src.tar.gz \
	&& tar -zxvf JSAP-2.1-src.tar.gz \
	&& rm -rf JSAP-2.1-src.tar.gz \
	&& cd JSAP-2.1 \
	&& ant compile-all \
	&& ant test \
	&& apt-get purge --auto-remove ant junit -y
ENV CLASSPATH /JSAP-2.1/lib/JSAP-2.1.jar:.
CMD ["/bin/bash"]
