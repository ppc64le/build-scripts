FROM ppc64le/openjdk:openjdk-8-jdk

# The author for this new image
MAINTAINER Snehlata Mohite smohite@us.ibm.com

#setting environment variables
ENV JAVA_HOME /usr/lib/jvm/java-1.8.0-openjdk-ppc64el
ENV PATH $PATH:$JAVA_HOME/bin
ENV MAVEN_HOME /apache-maven-3.3.9
ENV PATH $PATH:$MAVEN_HOME/bin
ENV ALFRESCO_VERSION 5.1.a

# Install dependencies  
#download and setup maven environment
RUN apt-get update && apt-get install -y wget tomcat7 subversion\
    && wget http://www.us.apache.org/dist/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz\
    && tar -xvzf apache-maven-3.3.9-bin.tar.gz\
    && ln -s /apache-maven-3.3.9/bin/mvn /usr/bin/mvn\
#source code checkout and building the package
    && svn checkout https://svn.alfresco.com/repos/alfresco-open-mirror/alfresco/COMMUNITYTAGS/${ALFRESCO_VERSION} alfresco-server && cd alfresco-server/root && mvn clean install\
#source code checkout and building the package
    && cd / && svn checkout https://svn.alfresco.com/repos/alfresco-open-mirror/web-apps/Share/trunk alfresco-webclient\
    && cd alfresco-webclient\
    && mvn clean install\
    && cd /usr/share/tomcat7/lib\
    && wget http://central.maven.org/maven2/mysql/mysql-connector-java/5.1.17/mysql-connector-java-5.1.17.jar\
    && cp /alfresco-webclient/alfresco/target/alfresco.war /var/lib/tomcat7/webapps\
    && cp /alfresco-webclient/share/target/share.war /var/lib/tomcat7/webapps\
    && sed -i '1 aexport JAVA_OPTS="-Xms1024m -Xmx10246m -XX:NewSize=256m -XX:MaxNewSize=356m -XX:PermSize=256m -XX:MaxPermSize=356m"' /usr/share/tomcat7/bin/catalina.sh\
    && sed -i '1 aexport JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el' /usr/share/tomcat7/bin/catalina.sh\
    && mkdir -p /Alfresco/alf_data\
    && rm -rf /apache-maven-3.3.9-bin.tar.gz\
    && rm -rf /alfresco-server && rm -rf /alfresco-webclient\
    && apt-get purge -y wget subversion && apt-get -y autoremove

#port expose 8080
EXPOSE 8080

WORKDIR /Alfresco
RUN chown -R tomcat7 alf_data

WORKDIR /
COPY automate.sh /automate.sh
RUN chmod +x /automate.sh
CMD ./automate.sh
