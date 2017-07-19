FROM ppc64le/openjdk:openjdk-8-jdk

# The author for this new image
MAINTAINER Snehlata Mohite smohite@us.ibm.com


#setting environment variables
ENV JAVA_HOME /usr/lib/jvm/java-1.8.0-openjdk-ppc64el
ENV PATH $PATH:$JAVA_HOME/bin
ENV MAVEN_HOME /apache-maven-3.3.9
ENV PATH $PATH:$MAVEN_HOME/bin

# Install dependencies  
#download and setup maven environment
RUN apt-get update && apt-get install -y wget\
    && apt-get install -y tomcat7 \
    && wget http://www.us.apache.org/dist/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz\
    &&  tar -xvzf apache-maven-3.3.9-bin.tar.gz\
    &&  ln -s /apache-maven-3.3.9/bin/mvn /usr/bin/mvn\
    &&  apt-get install -y subversion
#source code checkout and building the package
RUN svn checkout https://svn.alfresco.com/repos/alfresco-open-mirror/alfresco/HEAD alfresco-server && cd alfresco-server/root && mvn clean install

#source code checkout and building the package
RUN svn checkout https://svn.alfresco.com/repos/alfresco-open-mirror/web-apps/Share/trunk alfresco-webclient

WORKDIR /alfresco-webclient
RUN mvn clean install ; exit 0

#port expose 8080
EXPOSE 8080

WORKDIR /usr/share/tomcat7/lib

#copy the required wars to application server
RUN wget http://central.maven.org/maven2/mysql/mysql-connector-java/5.1.17/mysql-connector-java-5.1.17.jar\
    &&  cp /alfresco-webclient/alfresco/target/alfresco.war /var/lib/tomcat7/webapps\
    &&  cp /alfresco-webclient/share/target/share.war /var/lib/tomcat7/webapps\
    &&  sed -i '1 aexport JAVA_OPTS="-Xms1024m -Xmx10246m -XX:NewSize=256m -XX:MaxNewSize=356m -XX:PermSize=256m -XX:MaxPermSize=356m"' /usr/share/tomcat7/bin/catalina.sh\
    &&  sed -i '1 aexport JAVA_HOME=/usr/lib/jvm/java-8-openjdk-ppc64el' /usr/share/tomcat7/bin/catalina.sh\
    &&  mkdir -p /Alfresco/alf_data

env tomcat_home=/var/lib/tomcat7

WORKDIR /Alfresco
RUN chown -R tomcat7 alf_data

WORKDIR /
COPY automate.sh /automate.sh
RUN chmod +x /automate.sh
CMD ./automate.sh
