# Steps for creating che-nodejs10-ubi docker image in UBI on POWER 
 1. Ensure that Latest docker version should be installed
 2. Execute following commands:
 
 ```bash
git clone -b 7.3.x https://github.com/eclipse/che-devfile-registry.git
git checkout tags/7.3.2
rm -rf che-devfile-registry/arbitrary-users-patch/base_images
mv base_images che-devfile-registry/arbitrary-users-patch
```
3.Build che-nodejs10-ubi

```bash
./build_images.sh
```
4.Tag che-nodejs10-ubi

```bash
docker tag <image_id> <tag_name>
docker push <repository_name>
```
