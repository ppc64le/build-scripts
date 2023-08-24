#docker-alpine

git clone https://github.com/openzipkin/docker-alpine.git
cd docker-alpine

sed -i '32d' Dockerfile
sed -i '31 aFROM ppc64le/alpine:3.16.2 as install' Dockerfile

sed -i '79d' Dockerfile
sed -i '78 a\  apk add --no-cache libcrypto3=3.1.1-r1 libssl3=3.1.1-r1 && \\' Dockerfile

sed -i '32 a\  ppc64le* )' alpine_minirootfs
sed -i '33 a\    arch=ppc64le' alpine_minirootfs
sed -i '34 a\    ;;' alpine_minirootfs

./build-bin/build 
cd ..


#docker-java
git clone https://github.com/openzipkin/docker-java.git
cd docker-java

sed -i '9d' Dockerfile
sed -i '8 aARG docker_parent_image=openzipkin/alpine:test' Dockerfile

sed -i '23d' build-bin/docker/docker_build
sed -i '22 aDOCKER_BUILDKIT=1 docker build ${docker_args} --tag ${docker_tag} .' build-bin/docker/docker_build

#Here we are using docker-java version 15.0.8_p4-r2, as docker-alpine image has highest java version 15.0.8_p4-r2 on ppc64le. And we have used docker-alpine as base image for docker-java.
./build-bin/build 15.0.8_p4-r2
cd ..

#zipkin

git clone https://github.com/openzipkin/zipkin.git
cd zipkin/zipkin
#Dependencies
yum install -y tzdata tzdata-java java-11-openjdk-devel git wget 
export JAVA_HOME=/usr/lib/jvm/$(ls /usr/lib/jvm/ | grep -P '^(?=.*java-11)(?=.*ppc64le)')
export PATH=$JAVA_HOME/bin:$PATH

#installing maven 3.8.6
wget http://archive.apache.org/dist/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.tar.gz
tar -C /usr/local/ -xzvf apache-maven-3.8.6-bin.tar.gz
rm -rf tar xzvf apache-maven-3.8.6-bin.tar.gz
mv /usr/local/apache-maven-3.8.6 /usr/local/maven
export M2_HOME=/usr/local/maven
export PATH=$PATH:$M2_HOME/bin

mvn -DskipTests package

cd ..

