# Steps for creating remote-plugin-php7 docker image on POWER

 1. Ensure that Latest docker version should be installed
 2. Execute following commands:
 
 ```bash
git clone -b 7.3.2 https://github.com/eclipse/che-theia.git
cd che-theia/dockerfiles/remote-plugin-php7
rm -rf che-theia/dockerfiles/remote-plugin-php7/Dockerfile
mv Dockerfile che-theia/dockerfiles/remote-plugin-php7
```
3.Build remote-plugin-php7

```bash
docker build -t <repository_name> .
```
