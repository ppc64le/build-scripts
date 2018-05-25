FROM openjdk:8-jdk
MAINTAINER "Yugandha Deshpande <yugandha@us.ibm.com>"

ENV DERBY_VERSION 10.14.1.0
ENV DERBY_INSTALL /home/derby
ENV DERBY_HOME /derby-data
ENV CLASSPATH=$DERBY_INSTALL/lib/derbynet.jar:$DERBY_INSTALL/lib/derbytools.jar:$DERBY_INSTALL/lib/derby.jar:$DERBY_INSTALL/lib/derbyoptionaltools.jar:$DERBY_INSTALL/lib/derbyrun.jar:$DERBY_INSTALL/lib/derbyclient.jar

RUN apt-get update \
	&& apt-get install ant -y \
	&& git clone https://github.com/apache/derby.git \
	&& cd derby && git checkout $DERBY_VERSION \
	&& ant -quiet clobber \
	&& ant -quiet buildsource \
	&& ant -quiet buildjars \
	&& java -jar jars/sane/derbyrun.jar sysinfo \
	&& mkdir /home/derby /home/derby/lib /derby-data \
	&& cp -R /derby/jars/sane/* /home/derby/lib \
	&& cp -R /derby/generated/* /home/derby/ \
	&& cd .. && rm -rf /derby \
	&& apt-get purge --auto-remove ant -y 
ENV SHELL /bin/bash
ENV PATH $PATH:$DERBY_INSTALL/bin

VOLUME ["/derby-data"]
EXPOSE 1527

CMD startNetworkServer -h 0.0.0.0
