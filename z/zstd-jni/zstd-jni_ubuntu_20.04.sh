# Install dependencies
apt-get update -y
apt-get install -y openjdk-11-jdk gcc git curl gnupg


echo "deb https://dl.bintray.com/sbt/debian /" | sudo tee -a /etc/apt/sources.list.d/sbt.list
curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | sudo apt-key add

sudo apt-get install sbt

git clone https://github.com/luben/zstd-jni
cd zstd-jni
./sbt compile
./sbt jacoco
