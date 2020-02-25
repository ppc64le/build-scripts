# Steps for creating che-python-3.7 docker image on POWER
 1. Ensure that Latest docker version should be installed
 2. Execute following commands:
 
 ```bash
git clone -b 7.3.x https://github.com/eclipse/che-devfile-registry.git
git checkout tags/7.3.2
rm -rf che-devfile-registry/arbitrary-users-patch/base_images
mv base_images che-devfile-registry/arbitrary-users-patch
```
3.Build che-python-3.7

```bash
./build_images.sh
```
4.Tag che-python-3.7

```bash
docker tag <image_id> <tag_name>
docker push <repository_name>
```
