PACKAGE_VERSION=2.13.6

echo "Usage: $0 [-v <PACKAGE_VERSION>]"
echo "       PACKAGE_VERSION is an optional paramater whose default value is 2.13.6"

PACKAGE_VERSION="${1:-$PACKAGE_VERSION}"

yum update -y
yum install -y git curl

#install java
yum install -y java java-devel
which java
ls /usr/lib/jvm/
export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.312.b07-1.el8_4.ppc64le

#update path
export PATH=$PATH:$JAVA_HOME/bin

#install sbt
rm -f /etc/yum.repos.d/bintray-rpm.repo
curl -L https://www.scala-sbt.org/sbt-rpm.repo > sbt-rpm.repo
mv sbt-rpm.repo /etc/yum.repos.d/
yum install -y sbt

git clone https://github.com/scala/scala
cd scala
git checkout v$PACKAGE_VERSION
sbt compile


#sample project using scala to test
mkdir testpro
cd testpro
sbt new scala/hello-world.g8
#input 'hello world' when prompted
cd hello-world
sbt compile
sbt run

