FROM openjdk:8-jdk
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

RUN apt-get update -y \
	&& apt-get install -y ant \
	# Download source 
	&& git clone https://github.com/apache/incubator-freemarker \
	&& cd incubator-freemarker && git checkout v2.3.28 \
	# Build source
	&& ant download-ivy && ant update-deps \
	&& ant && ant test \
	&& apt-get purge --auto-remove ant -y 

CMD ["/bin/bash"]
