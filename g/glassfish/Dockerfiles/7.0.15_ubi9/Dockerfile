#Base image for this dockerfile
FROM registry.access.redhat.com/ubi9/ubi:9.3

#Author of the new image
MAINTAINER "Ramnath Nayak <Ramnath.Nayak@ibm.com>"

#Environment Variables
ENV GLASSFISH_PKG  https://github.com/eclipse-ee4j/glassfish/releases/download/7.0.15/glassfish-7.0.15.zip
ENV PKG_FILE_NAME glassfish-7.0.15.zip

RUN yum install -y git wget zip

# Install Java 
RUN	wget https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.6%2B10/OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.6_10.tar.gz && \
	tar -C /usr/local -xzf OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.6_10.tar.gz && \
	export JAVA_HOME=/usr/local/jdk-17.0.6+10 && \
	export JAVA17_HOME=/usr/local/jdk-17.0.6+10 && \
	export PATH=$PATH:/usr/local/jdk-17.0.6+10/bin && \
	ln -sf /usr/local/jdk-17.0.6+10/bin/java /usr/bin && \
	rm -f OpenJDK17U-jdk_ppc64le_linux_hotspot_17.0.6_10.tar.gz && \
	java -version && \
	wget https://dlcdn.apache.org/maven/maven-3/3.9.8/binaries/apache-maven-3.9.8-bin.tar.gz && \
	tar -xvzf apache-maven-3.9.8-bin.tar.gz && \
	cp -R apache-maven-3.9.8 /usr/local && \
	ln -s /usr/local/apache-maven-3.9.8/bin/mvn /usr/bin/mvn && \
	rm -f apache-maven-3.9.8-bin.tar.gz && \
	mvn -version && \
	adduser -b /opt -m -s /bin/bash glassfish && echo glassfish:glassfish | chpasswd && \
	wget $GLASSFISH_PKG && unzip glassfish-7.0.15.zip && rm $PKG_FILE_NAME && \
    chown -R glassfish:glassfish /opt/glassfish* && \
    sed -i 's/-client/-server/' /opt/glassfish/glassfish7/glassfish/domains/domain1/config/domain.xml

# Default glassfish ports
EXPOSE 4848 8009 8080 8181

# Set glassfish user in its home/bin by default
USER glassfish
WORKDIR /opt/glassfish/glassfish7/bin

# User: admin / Pass: glassfish
RUN echo "admin;{SSHA256}80e0NeB6XBWXsIPa7pT54D9JZ5DR5hGQV1kN1OAsgJePNXY6Pl0EIw==;asadmin" > /opt/glassfish/glassfish7/glassfish/domains/domain1/config/admin-keyfile
RUN echo "AS_ADMIN_PASSWORD=glassfish" > pwdfile

# Default to admin/glassfish as user/pass
RUN \
  ./asadmin start-domain && \
  ./asadmin --user admin --passwordfile pwdfile enable-secure-admin && \
  ./asadmin stop-domain

RUN echo "export PATH=$PATH:/opt/glassfish/glassfish7/bin" >> /opt/glassfish/.bashrc

# Default command to run on container boot
CMD ["/opt/glassfish/glassfish7/bin/asadmin", "start-domain", "--verbose=true"]
