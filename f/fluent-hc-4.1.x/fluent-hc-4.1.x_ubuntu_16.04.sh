# Install dependencies
apt update -y
apt install -y git maven openjdk-8-jdk

git clone https://github.com/rholder/fluent-hc-4.1.x.git

cd fluent-hc-4.1.x/
sed 's/1.5/1.8/g' pom.xml > tmp
mv tmp pom.xml

mvn install
