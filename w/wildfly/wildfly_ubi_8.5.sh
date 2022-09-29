PACKAGE_NAME=wildfly
PACKAGE_VERSION=${1:-27.0.0.Alpha5}
PACKAGE_URL=https://github.com/wildfly/wildfly.git

yum update -y
yum install git wget  tar


yum install java-11-openjdk-devel


# Install maven.
cd /opt/
wget https://www-eu.apache.org/dist/maven/maven-3/3.6.3/binaries/apache-maven-3.6.3-bin.tar.gz
tar xzf apache-maven-3.6.3-bin.tar.gz
ln -s apache-maven-3.6.3 maven
export MVN_HOME=/opt/maven
export PATH=${MVN_HOME}/bin:${PATH}
mvn -version


cd /home
rm -rf $PACKAGE_NAME
git clone $PACKAGE_URL

cd  $PACKAGE_NAME
git checkout $PACKAGE_VERSION

mvn install

mvn clean install -DskipTests


