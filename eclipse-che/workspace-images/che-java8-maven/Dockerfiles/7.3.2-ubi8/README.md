# Steps for creating che-java8-maven docker image on POWER

1. Execute following command:
```bash
git clone https://github.com/AdoptOpenJDK/openjdk-docker.git
```
2.Build openjdk 8 UBI 

```
cd openjdk-docker
docker build -t openjdk8:ubi -f 8/jdk/ubi/Dockerfile.hotspot.nightly.full .

```
2. Download following files from this page:
Dockerfile
3. Execute following commands:
```bash
git clone https://github.com/carlossg/docker-maven.git
mv Dockerfile docker-maven/jdk-8/Dockerfile
cd docker-maven/jdk-8/
```
4. Build the image:
```bash
docker build -t <repository> Dockerfile .
docker push <repository>/maven-jdk8:ppc64le
```
5. Execute following commands:
 
 ```bash
git clone -b 7.3.x https://github.com/eclipse/che-devfile-registry.git
git checkout tags/7.3.2
rm -rf che-devfile-registry/arbitrary-users-patch/base_images
mv base_images che-devfile-registry/arbitrary-users-patch
```
3.Build maven-jdk8

```bash
./build_images.sh
```
4.Tag maven-jdk8

```bash
docker tag <image_id> <tag_name>
docker push <repository_name>

```
