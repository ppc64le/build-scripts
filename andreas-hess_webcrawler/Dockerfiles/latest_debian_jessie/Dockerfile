FROM ppc64le/openjdk:openjdk-8-jdk

MAINTAINER "Priya Seth <sethp@us.ibm.com>"

ENV JAVA_HOME /usr/lib/jvm/java-1.8.0-openjdk-ppc64el
ENV PATH $PATH:$JAVA_HOME/bin
ENV CLASSPATH $CLASSPATH:/multiweb/classes

RUN wget http://andreas-hess.info/programming/webcrawler/multiweb.zip && unzip multiweb.zip -d multiweb && \
	cd multiweb && mkdir classes && \
	javac -d ./classes ie/moguntia/threads/*.java && \
	javac -d ./classes -cp ./classes ie/moguntia/webcrawler/*.java && \
	java -cp ./classes ie.moguntia.webcrawler.WSDLCrawler https://www.google.co.in/ abc \
	&& rm -rf /multiweb.zip

CMD ["/bin/bash"]

