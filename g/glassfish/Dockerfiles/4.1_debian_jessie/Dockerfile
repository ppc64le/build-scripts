#Base image for this dockerfile
FROM ppc64le/openjdk:8-jdk
#Author of the new image
MAINTAINER "AMITKUMAR GHATWAL"

#Environment Variables
ENV GLASSFISH_PKG  http://download.java.net/glassfish/4.1/release/glassfish-4.1.zip
ENV PKG_FILE_NAME glassfish-4.1.zip
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-ppc64el
ENV CONFIG_JVM_ARGS -Djava.security.egd=file:/dev/./urandom

# Install dependencies, Download Glassfish 4.1 source code
RUN apt-get update && \
        useradd -b /opt -m -s /bin/bash glassfish && echo glassfish:glassfish | chpasswd && \
        cd /opt/glassfish && wget $GLASSFISH_PKG && unzip glassfish-4.1.zip && rm $PKG_FILE_NAME && \
        chown -R glassfish:glassfish /opt/glassfish* && \
        sed -i 's/-client/-server/' /opt/glassfish/glassfish4/glassfish/domains/domain1/config/domain.xml

# Default glassfish ports
EXPOSE 4848 8009 8080 8181

# Set glassfish user in its home/bin by default
USER glassfish
WORKDIR /opt/glassfish/glassfish4/bin

# User: admin / Pass: glassfish
RUN echo "admin;{SSHA256}80e0NeB6XBWXsIPa7pT54D9JZ5DR5hGQV1kN1OAsgJePNXY6Pl0EIw==;asadmin" > /opt/glassfish/glassfish4/glassfish/domains/domain1/config/admin-keyfile
RUN echo "AS_ADMIN_PASSWORD=glassfish" > pwdfile

# Default to admin/glassfish as user/pass
RUN \
  ./asadmin start-domain && \
  ./asadmin --user admin --passwordfile pwdfile enable-secure-admin && \
  ./asadmin stop-domain

RUN echo "export PATH=$PATH:/opt/glassfish/glassfish4/bin" >> /opt/glassfish/.bashrc

# Default command to run on container boot
CMD ["/opt/glassfish/glassfish4/bin/asadmin", "start-domain", "--verbose=true"]

