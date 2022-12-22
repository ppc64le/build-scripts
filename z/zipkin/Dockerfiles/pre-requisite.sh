
#docker-alpine
git clone https://github.com/openzipkin/docker-alpine.git
cd docker-alpine

sed -i '32d' Dockerfile
sed -i '31 aFROM ppc64le/alpine:3.12.1 as install' Dockerfile

sed -i '32 a\  ppc64le* )' alpine_minirootfs
sed -i '33 a\    arch=ppc64le' alpine_minirootfs
sed -i '34 a\    ;;' alpine_minirootfs

./build-bin/build 3.16.2
cd ..

#docker-java
git clone https://github.com/openzipkin/docker-java.git
cd docker-java

sed -i '9d' Dockerfile
sed -i '8 aARG docker_parent_image=openzipkin/alpine:test' Dockerfile

sed -i '23d' build-bin/docker/docker_build
sed -i '22 aDOCKER_BUILDKIT=1 docker build ${docker_args} --tag ${docker_tag} .' build-bin/docker/docker_build
./build-bin/build 17.0.5_p8
cd ..


#zipkin
git clone https://github.com/openzipkin/zipkin.git
cd zipkin/zipkin
yum install -y java-11-openjdk-devel maven 
mvn -DskipTests package
# ensure zipkin-server/target/zipkin-server-*slim.jar & zipkin-server/target/zipkin-server-*exec.jar  jars are created
ls -l target/

#sed -i '23d' build-bin/docker/docker_build
#sed -i '22 aDOCKER_BUILDKIT=1 docker build ${docker_args} --tag ${docker_tag} .' build-bin/docker/docker_build

#sed -i '33d' docker/Dockerfile
#sed -i '32 aFROM openzipkin/java:test as install' docker/Dockerfile

#sed -i '49,52d' docker/Dockerfile
#sed -i '48 aRUN mkdir zipkin && cd zipkin && \' docker/Dockerfile
#sed -i '49 a\    jar -xf /code/zipkin-server/target/zipkin-server-*exec.jar && cd .. && \' docker/Dockerfile
#sed -i '50 a\    mkdir zipkin-slim && cd zipkin-slim && \' docker/Dockerfile
#sed -i '51 a\    jar -xf /code/zipkin-server/target/zipkin-server-*slim.jar && cd ..' docker/Dockerfile

#sed -i '55d' docker/Dockerfile
#sed -i '54 aFROM openzipkin/java:test-jre as base-server' docker/Dockerfile

#build-bin/docker/docker_build openzipkin/zipkin:test
cd ..

